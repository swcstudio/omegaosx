# Deep Dive: Network Stack

## Overview

The `kernel/src/net/` directory (97 files) implements a modular network stack for OmegaOS W3.x, focusing on socket abstractions for POSIX compliance, kernel-user communication, and virtual networking. Key components: `socket/` (core trait for bind/connect/listen/accept/shutdown/sendmsg/recvmsg, sub-protocols IP/Unix/Netlink/Vsock with options/flags), `iface/` (BigTCP integration for TCP/UDP over loopback/virtio interfaces, poll/sched), `uts_ns.rs` (UTS namespace for hostname/domainname with cap SYS_ADMIN). Supports ~5000 LOC of networking, emphasizing secure, low-latency AR protocols via BigTCP, netlink events, unix local comm.

This subsystem provides secure isolation (caps/reuse_addr/port), multicast (netlink groups), and virtio vsock for AR guests. Patterns: Trait-based delegation, state machines (Init/Connecting/Connected/Listen), RwLock options/atomic nonblocking, pollee IoEvents for async I/O. Flows integrate syscalls (socket/bind/sendto), FileLike read/write, process ns (uts/unix/netlink). Ties to WEB3.ARL for AR sockets/events/protocols.

## Inventory

- **mod.rs**: Exports iface/socket/uts_ns; init() (iface/netlink/vsock), init_in_first_kthread() (iface).
- **socket/** (70+ files): mod.rs (Socket trait/private block_on, FileLike impl read/write status_flags), util/ (options/SocketOptionSet get/set level IP TCP NoDelay/MaxSeg/KeepIdle/SynCnt/DeferAccept/WindowClamp/Congestion/UserTimeout/Inq, send_recv_flags/MSG_DONTROUTE/DONTWAIT/NOSIGNAL/MORE, socket_addr/SocketAddr enum IPv4/Netlink/Unix/Vsock, message_header/ControlMessage, shutdown_cmd/SHUT_RD/WR/RDWR, datagram_common/Bound/Unbound bind/try_recv/select_remote_bind), ip/ (mod.rs addr/common/datagram/options/stream, stream/mod.rs Connected/Connecting/Init/Listen/Observer options, datagram/Bound/Unbound/Observer), unix/ (mod.rs addr/cred/ctrl_msg/datagram/ns/abs/path/stream, stream/mod.rs Socket/Listener/Connected/Backlog incoming_conns/cred/pass_cred, datagram/Socket/Message, ns/abs/AbstractHandle BTreeMap, path/create/lookup_socket_file), netlink/ (mod.rs addr/common/kobject_uevent/message/options/receiver/route/table, addr/NetlinkSocketAddr port/group GroupIdSet, common/BoundNetlink/Unbound/BoundHandle, kobject_uevent/mod.rs Socket, message/uevent/Uevent SysObjAction add/remove/change, syn_uevent key-value SYNTH_ARG_, test.rs, mod.rs QueueableMessage, route/mod.rs RtnlMessage/Bound, kernel/util/link/addr, message/segment/header/common/ack/attr/noattr/route/legacy/link/addr, table/ProtocolSocketTable RwMutex unicast BTreeMap/multicast VecDeque bind/multicast/unicast StandardNetlinkProtocol ROUTE/UEVENT), vsock/ (mod.rs addr/common/stream, addr/VsockSocketAddr, common/VsockSpace, stream/Socket/Listen/Init/Connecting/Connected), options/macros/impl_socket_options AddMembership/DropMembership.
- **iface/** (5 files): mod.rs (ext/BigtcpExt, init/iter_all_ifaces/loopback_iface/virtio_iface, poll/init_in_first_kthread, Iface/BoundPort RawTcpSocketExt TcpConnection/Listener UdpSocket), sched.rs, poll.rs.
- **uts_ns.rs**: UtsNamespace singleton/clone, uts_name RwMutex<UtsName> padded fields, set_hostname/domainname copy_from_user cap SYS_ADMIN.

## Key Snippets

### Socket Trait (`kernel/src/net/socket/mod.rs`)
```rust
pub trait Socket: private::SocketPrivate + Send + Sync {
    fn bind(&self, _socket_addr: SocketAddr) -> Result<()> { /* EOPNOTSUPP */ }
    fn connect(&self, _socket_addr: SocketAddr) -> Result<()> { /* EOPNOTSUPP */ }
    fn listen(&self, _backlog: usize) -> Result<()> { /* EOPNOTSUPP */ }
    fn accept(&self) -> Result<(Arc<dyn FileLike>, SocketAddr)> { /* EOPNOTSUPP */ }
    fn shutdown(&self, _cmd: SockShutdownCmd) -> Result<()> { /* EOPNOTSUPP */ }
    fn addr(&self) -> Result<SocketAddr> { /* EOPNOTSUPP */ }
    fn peer_addr(&self) -> Result<SocketAddr> { /* EOPNOTSUPP */ }
    fn get_option(&self, _option: &mut dyn SocketOption) -> Result<()> { /* EOPNOTSUPP */ }
    fn set_option(&self, _option: &dyn SocketOption) -> Result<()> { /* EOPNOTSUPP */ }
    fn sendmsg(&self, reader: &mut dyn MultiRead, message_header: MessageHeader, flags: SendRecvFlags) -> Result<usize>;
    fn recvmsg(&self, writer: &mut dyn MultiWrite, flags: SendRecvFlags) -> Result<(usize, MessageHeader)>;
}

impl<T: Socket + 'static> FileLike for T {
    fn read(&self, writer: &mut VmWriter) -> Result<usize> {
        self.recvmsg(writer, SendRecvFlags::empty()).map(|(len, _)| len)
    }
    fn write(&self, reader: &mut VmReader) -> Result<usize> {
        self.sendmsg(reader, MessageHeader::new(None, Vec::new()), SendRecvFlags::empty())
    }
    fn status_flags(&self) -> StatusFlags { self.is_nonblocking().then_some(StatusFlags::O_NONBLOCK).unwrap_or_default() }
}
```
- Abstracts socket ops; FileLike for read/write on fds.

### IP Stream Socket (`kernel/src/net/socket/ip/stream/mod.rs`)
```rust
pub struct StreamSocket {
    state: RwLock<Takeable<State>>, // Init/Connecting/Connected/Listen
    options: RwLock<OptionSet>, // SocketOptionSet/IpOptionSet/TcpOptionSet
    is_nonblocking: AtomicBool,
    pollee: Pollee,
}

enum State { Init(InitStream), Connecting(ConnectingStream), Connected(ConnectedStream), Listen(ListenStream) }

impl Socket for StreamSocket {
    fn connect(&self, socket_addr: SocketAddr) -> Result<()> {
        let remote_endpoint = socket_addr.try_into()?;
        if let Some(result) = self.start_connect(&remote_endpoint) { return result; }
        self.wait_events(IoEvents::OUT, None, || self.check_connect())
    }
    fn sendmsg(&self, reader: &mut dyn MultiRead, message_header: MessageHeader, flags: SendRecvFlags) -> Result<usize> {
        if !control_messages.is_empty() { warn!("sending control message not supported"); }
        self.block_on(IoEvents::OUT, || self.try_send(reader, flags))
    }
    // Similar for bind/listen/accept/shutdown/addr/peer_addr/get/set_option/recvmsg
}

fn do_tcp_setsockopt(option: &dyn SocketOption, options: &mut OptionSet, state: &mut State) -> Result<NeedIfacePoll> {
    match_sock_option_ref!(option, {
        tcp_no_delay: NoDelay => { options.tcp.set_no_delay(*no_delay); state.set_raw_option(|raw| raw.set_nagle_enabled(!no_delay)); }
        // MaxSeg/KeepIdle/SynCnt/DeferAccept/WindowClamp/Congestion/UserTimeout/Inq
    });
}
```
- State machine with RwLock<Takeable<State>> for connect/listen transitions; options propagate to raw BigTCP; block_on for nonblock.

### Netlink (`kernel/src/net/socket/netlink/mod.rs`, `table/mod.rs`)
```rust
pub struct NetlinkSocketAddr { port: PortNum, groups: GroupIdSet } // PortNum u32, GroupIdSet bitmask<32>

pub struct ProtocolSocketTable<Message> {
    unicast_sockets: BTreeMap<PortNum, MessageReceiver<Message>>,
    multicast_groups: [VecDeque<BoundHandle<Message>>; MAX_GROUPS],
}

impl SupportedNetlinkProtocol for NetlinkRouteProtocol {
    type Message = RtnlMessage;
    fn socket_table() -> &'static RwMutex<ProtocolSocketTable<Self::Message>> { &NETLINK_SOCKET_TABLE.get().unwrap().route }
}

fn bind(socket_table: &'static RwMutex<ProtocolSocketTable<Message>>, addr: &NetlinkSocketAddr, receiver: MessageReceiver<Message>) -> Result<BoundHandle<Message>> {
    let mut protocol_sockets = socket_table.write();
    let port = if addr.port == UNSPECIFIED_PORT { random_port() } else { addr.port };
    if protocol_sockets.unicast_sockets.contains_key(&port) { Errno::EADDRINUSE }
    protocol_sockets.unicast_sockets.insert(port, receiver);
    Ok(BoundHandle::new(socket_table, port, addr.groups()))
}

pub fn multicast(dst_groups: GroupIdSet, message: Message) { /* enqueue to multicast_groups */ }
```
- Table per-protocol (route/uevent) with BTreeMap unicast/multicast VecDeque; bind port/group, multicast to groups.

### Unix Stream (`kernel/src/net/socket/unix/stream/mod.rs`, `listener.rs`)
```rust
pub struct UnixStreamSocket { /* ... */ }
pub struct Backlog {
    addr: UnixSocketAddrBound,
    incoming_conns: SpinLock<Option<VecDeque<Connected>>>,
    connect_wait_queue: WaitQueue,
    listener_cred: SocketCred<ReadDupOp>,
    is_seqpacket: bool,
}

impl Listener for UnixStreamListener {
    fn try_accept(&self, is_seqpacket: bool) -> Result<(Arc<dyn FileLike>, SocketAddr)> {
        let connected = self.backlog.pop_incoming()?;
        let peer_addr = connected.peer_addr().into();
        let socket = UnixStreamSocket::new_connected(connected, options, false, is_seqpacket);
        Ok((socket, peer_addr))
    }
}

pub fn create_abstract_name(name: Arc<[u8]>) -> Result<Arc<AbstractHandle>> { /* BTreeMap handles */ }
```
- Backlog for incoming, cred/pass_cred, abstract/path ns (BTreeMap<Arc<[u8]>, Weak<AbstractHandle>>).

### Vsock (`kernel/src/net/socket/vsock/mod.rs`)
```rust
pub static VSOCK_GLOBAL: Once<Arc<VsockSpace>> = Once::new();
pub fn init() {
    if let Some(driver) = get_device(DEVICE_NAME) {
        VSOCK_GLOBAL.call_once(|| Arc::new(VsockSpace::new(driver)));
        register_recv_callback(DEVICE_NAME, || { let vsockspace = VSOCK_GLOBAL.get().unwrap(); vsockspace.poll().unwrap(); });
    }
}
pub use stream::VsockStreamSocket;
```
- VsockSpace with virtio driver, recv_callback poll.

### UTS Namespace (`kernel/src/net/uts_ns.rs`)
```rust
pub struct UtsNamespace { uts_name: RwMutex<UtsName>, owner: Arc<UserNamespace> }
#[repr(C)] pub struct UtsName { sysname: [u8;65], nodename: [u8;65], /* ... domainname */ }

pub fn set_hostname(&self, addr: Vaddr, len: usize, ctx: &Context) -> Result<()> {
    self.owner.check_cap(CapSet::SYS_ADMIN, ctx.posix_thread)?;
    let new_host_name = copy_uts_field_from_user(addr, len as _, ctx)?; // nul-term padded
    self.uts_name.write().nodename = new_host_name;
    Ok(())
}
```
- Padded C strings, cap check, copy_from_user with len limit.

## Architecture and Patterns

- **Abstraction**: Socket trait delegates to protocol-specific (IP/Unix/Netlink/Vsock) impls; FileLike for fd read/write; private SocketPrivate for nonblock/block_on IoEvents.
- **State Management**: StreamSocket RwLock<Takeable<State>> (Init/Connecting/Connected/Listen transitions on connect/listen/accept); atomic is_nonblocking; pollee invalidate/poll iface.
- **Options**: SocketOptionSet (get/set level SOL_SOCKET/IP/TCP, e.g., ReuseAddr/Port/Linger/KeepAlive/PassCred/Priority, NoDelay/MaxSeg/KeepIdle); raw BigTCP RawTcpOption (nagle/keepalive); match_sock_option for handling.
- **Concurrency**: RwLock state/options, SpinLock incoming_conns, WaitQueue connect/block, disable_preempt? No, but pollee for async; netlink RwMutex table BTreeMap/VVecDeque bind/multicast.
- **Security**: Cap SYS_ADMIN (uts set_hostname, netlink bind?), reuse_addr/port to prevent bind races, pass_cred for unix auth, abstract ns isolation.
- **Patterns**: Delegation (trait Socket/FileLike/Pollable), Event-driven (pollee check_io_events wait_events), Copy-on-write? (clone addr/cred), Guard (RwLockReadGuard for updated state).

## Integration

- **Syscalls**: socket(domain/type/protocol) -> bind/connect/sendto/recvfrom/accept/shutdown/setsockopt/getsockopt/getsockname/getpeername; integrated via syscall table, user_space reader/writer for msg.
- **Threading**: Pollee/PollHandle for async I/O, block_on wait_events, nonblock EAGAIN/EINPROGRESS.
- **Time**: KeepIdle/UserTimeout for TCP, DeferAccept retrans, but no explicit timers here (ties to process timers?).
- **FS**: Unix path/abs create/lookup_socket_file InodeType::Socket, file_table dup/share on connect.
- **VM**: VmReader/Writer for send/recv, Vmar? Indirect via user_space.
- **Process/NS**: UtsNamespace clone/unshare, unix/netlink nsproxy, cred check cap SYS_ADMIN, peer_cred.
- **Other**: BigTCP iface poll for packets, virtio vsock device recv_callback, netlink table init() for route/uevent.

## WEB3.ARL Ties

- **Secure Sockets**: Netlink uevent/multicast for AR device events/hotplug (kobject add/remove/change), unix local AR comm (pass_cred abstract isolation), ip/tcp remote AR protocols (BigTCP low-latency NoDelay/UserTimeout, cap checks bind/connect).
- **AR Protocols**: Vsock for virt AR guests (stream over virtio), UTS hostname for AR node discovery, options (Congestion/WindowClamp) for AR bandwidth, multicast groups for AR broadcasts.
- **Isolation**: Reuse_port/addr with caps prevent AR app socket races, peer_cred/groups for AR peer auth, ns unshare for AR container nets.
- **ABI Preservation**: POSIX sockets (MSG_* flags, SO_* options) ensure portable AR apps; secure checks no privilege escalation in AR envs.

## Testing and TODOs

- **Existing**: osdk/tests/integration (socket bind/connect/send/recv, netlink bind/multicast, unix stream/datagram, vsock virtio?).
- **TODOs**:
  - Full TCP/UDP (BigTCP partial: connect/send/recv, add congestion control variants, syn flood protection).
  - Netlink: Multicast kernel-user (uevent synth UUID, route add/del link/addr), full RtnlMessage segments/attrs.
  - Vsock: Virtio full recv/send, space poll races.
  - Unix: Seqpacket support, control messages (SCM_RIGHTS/PASSFD), abstract races BTreeMap.
  - UTS: Sethostname/domainname races RwMutex, cap inheritance.
  - General: SIGPIPE on EPIPE (MSG_NOSIGNAL), hdrincl IP, peer_groups, batch sendmmsg/recvmsg, OOB data.

## Notes

- **Secure ABI**: POSIX sockets (reuse_addr/port/linger/keepalive/passcred), cap SYS_ADMIN uts/netlink; no leaks in bind/multicast.
- **Licensing**: MPL-2.0; AGL owners in docs.
- **Migration**: Gitbook Markdown; SEO (network stack, POSIX sockets, netlink route/uevent, unix domain, BigTCP TCP/UDP, virtio vsock, UTS namespace).
- **Guidance**: For AR, use netlink uevent for events, unix abstract for local, tcp NoDelay for low-latency; test multicast for AR pub/sub.
