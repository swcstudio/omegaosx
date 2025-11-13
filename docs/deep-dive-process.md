# Deep Dive: Process Management

## Overview

The `kernel/src/process/` directory (68 files) implements comprehensive process and thread management for OmegaOS W3.x, focusing on lifecycle (creation, execution, termination), signaling, namespaces, credentials, and virtual memory layout. Key subdirectories include `wait/` (process waiting), `term_status/` (termination status), `task_set/` (task sets), `sync/` (synchronization), `condvar/` (condition variables), `status/` (process states), `stats/` (statistics), `rlimit/` (resource limits), `signal/` (25 files for signal handling, queues, actions, masks), `posix_thread/` (10 files for POSIX threads, futex, robust lists, builders), `process/` (8 files for core Process struct and operations), `credentials/` (7 files for UID/GID/capabilities), `namespace/` (4 files for namespaces: proxy, unshare, user), `program_loader/` (5 files for ELF/shebang loading), `process_vm/` (3 files for VM layout: stack, heap, VMAR guards), plus utilities like `clone.rs`, `execve.rs`, `exit.rs`, `kill.rs`, `process_table.rs`, `pid_file/`, `filter/`, `timer_manager/`. 

This subsystem ensures secure, POSIX-compliant process isolation, with ties to WEB3.ARL for AR task containers via namespaces, capabilities, and signals. Patterns emphasize atomic operations, mutexes for state, and event-driven notifications (e.g., PidEvent observers). Flows integrate syscalls (clone/execve/exit/kill/wait), threading (pthread), timing (prof/virtual timers), FS (file_table unshare), and VM (vmar renewals). State management uses Arc<Process> with Mutex/RwLock for shared mutable data, handling zombie reaping and signal propagation.

## Inventory

- **wait/**: Process waiting mechanisms (waitpid, waitid).
- **term_status/**: Termination status (ExitCode, TermStatus::Killed).
- **task_set/**: Task collections (Mutex<TaskSet> in Process).
- **sync/**: Synchronization primitives for processes.
- **condvar/**: Condition variables for thread coordination.
- **status/**: ProcessStatus (zombie, running, stopped).
- **stats/**: ReapedChildrenStats, process statistics.
- **rlimit/**: ResourceLimits (RLIMIT_* constants).
- **signal/** (25 files): sig_action.rs (SigAction, flags like SA_RESTART/RESTORER), sig_disposition.rs (SigDispositions), sig_mask.rs (AtomicSigMask), sig_num.rs (SigNum), sig_queues.rs (SigQueues), pending.rs (dequeue_pending), poll.rs (signalfd polling), pause.rs (sigpause), c_types.rs (siginfo_t/ucontext_t), constants.rs (SIG* values), sig_stack.rs (SigStack), signals.rs (Signal trait).
- **posix_thread/** (10 files): mod.rs (PosixThread struct), builder.rs (PosixThreadBuilder), exit.rs (do_exit/do_exit_group), futex.rs (futex init), name.rs (ThreadName), posix_thread_ext.rs (AsPosixThread), robust_list.rs (RobustListHead), thread_local.rs (ThreadLocal), thread_table.rs (thread mappings).
- **process/** (8 files): mod.rs (Process struct), clone.rs (CloneFlags/Args), execve.rs (do_execve), exit.rs (exit_process), kill.rs (kill/tgkill), namespace/mod.rs (NsProxy/unshare/user_ns), program_loader/mod.rs (ProgramToLoad), process_vm/mod.rs (ProcessVm/InitStack/Heap).
- **credentials/** (7 files): mod.rs (Credentials<R>), c_types.rs, capabilities.rs (CapSet), credentials_.rs (Credentials_), group.rs (Gid), static_cap.rs, user.rs (Uid).
- **namespace/** (4 files): mod.rs, nsproxy.rs (NsProxy), unshare.rs, user_ns.rs (UserNamespace).
- **program_loader/** (5 files): mod.rs (ProgramToLoad, build_from_file), elf.rs (load_elf_to_vmar), shebang.rs (parse_shebang).
- **process_vm/** (3 files): mod.rs (ProcessVm, ProcessVmarGuard), heap.rs (Heap, USER_HEAP_SIZE_LIMIT), init_stack.rs (InitStack, AuxVec).
- **Utilities**: process_table.rs (PROCESS_TABLE BTreeMap<Pid,Process>), pid_file.rs, filter.rs, timer_manager.rs (PosixTimerManager).

## Key Snippets

### Core Process Structure (`kernel/src/process/process/mod.rs`)
```rust
pub struct Process {
    pid: Pid,
    vmar: Mutex<Option<Arc<Vmar>>>,
    children_wait_queue: WaitQueue,
    executable_path: RwLock<String>,
    tasks: Mutex<TaskSet>,
    status: ProcessStatus,
    parent: ParentProcess,
    children: Mutex<Option<BTreeMap<Pid, Arc<Process>>>>,
    process_group: Mutex<Weak<ProcessGroup>>,
    reaped_children_stats: Mutex<ReapedChildrenStats>,
    resource_limits: ResourceLimits,
    cgroup: RcuOption<Arc<CgroupNode>>,
    nice: AtomicNice,
    oom_score_adj: AtomicI16,
    is_child_subreaper: AtomicBool,
    has_child_subreaper: AtomicBool,
    sig_dispositions: Mutex<Arc<Mutex<SigDispositions>>>,
    sig_queues: SigQueues,
    parent_death_signal: AtomicSigNum,
    exit_signal: AtomicSigNum,
    prof_clock: Arc<ProfClock>,
    timer_manager: PosixTimerManager,
    user_ns: Mutex<Arc<UserNamespace>>,
}

pub fn enqueue_signal(&self, signal: impl Signal + Clone + 'static) {
    if self.status.is_zombie() { return; }
    self.sig_queues.enqueue(Box::new(signal));
    for task in self.tasks.lock().as_slice() {
        let posix_thread = task.as_posix_thread().unwrap();
        posix_thread.wake_signalled_waker();
    }
}
```
- Manages process state (VMAR, tasks, children, signals, timers, namespaces) with atomic/mutex guards.

### Cloning (`kernel/src/process/clone.rs`)
```rust
bitflags! {
    pub struct CloneFlags: u32 {
        const CLONE_VM = 0x00000100;
        // ... CLONE_FILES, CLONE_FS, CLONE_SIGHAND, CLONE_PIDFD, CLONE_THREAD, CLONE_NEWNS, etc.
        const CLONE_NS_FLAGS = Self::CLONE_NEWTIME.bits() | /* ... */;
    }
}

pub struct CloneArgs {
    flags: CloneFlags,
    pidfd: Pidfd,
    child_tid: TidPtr,
    parent_tid: TidPtr,
    exit_signal: SigNum,
    stack: Stack,
    tls: Tls,
}

pub fn clone_child(ctx: &Context, parent_context: &UserContext, clone_args: CloneArgs) -> Result<Tid> {
    // Check unsupported flags, clone VMAR/FS/files/sighand/sysvsem/pidfd/user_ns/ns_proxy
    // create_child_process, set_parent_and_group
}
```
- Supports subset of clone flags for VM/FS/files/signal sharing, namespaces; checks unsupported (e.g., CLONE_NEWUSER logs/warns).

### Execve (`kernel/src/process/execve.rs`)
```rust
pub fn do_execve(elf_file: Path, argv_ptr_ptr: Vaddr, envp_ptr_ptr: Vaddr, ctx: &Context, user_context: &mut UserContext) -> Result<()> {
    let argv = read_cstring_vec(/* ... */);
    let program_to_load = ProgramToLoad::build_from_file(elf_file.clone(), &fs_resolver, argv, envp, RECURSION_LIMIT)?;
    do_execve_no_return(ctx, user_context, &elf_file, &fs_resolver, program_to_load);
}

fn do_execve_no_return(/* ... */) {
    wait_other_threads(SIGKILL);
    unshare_renew_vmar();
    load_elf_to_vmar(/* ... */);
    set_cpu_context();
    apply_caps();
    reset_vfork();
    unshare_close_files();
    update_path();
    unshare_reset_sigdispositions();
}
```
- Loads ELF/shebang (with recursion limit), renews VMAR, sets auxv/heap/brk, applies caps, resets signals/files.

### Exit (`kernel/src/process/exit.rs`)
```rust
pub(super) fn exit_process(current_process: &Process) {
    current_process.status().set_zombie();
    drop_vmar(current_process);
    drop_pidfile();
    notify_parent();
    send_parent_death_signal(current_process);
    move_children_to_reaper_process(current_process);
    send_child_death_signal(current_process);
}

fn find_reaper(/* ... */) -> Arc<Process> { /* ... */ }
fn move_children(/* ... */) { /* Orphan handling */ }
```
- Sets zombie, drops resources, notifies parent/reaper, moves orphans.

### Kill/Signaling (`kernel/src/process/kill.rs` & `signal/mod.rs`)
```rust
// kill.rs
pub fn kill(pid: Pid, signal: Option<UserSignal>, ctx: &Context) -> Result<()> {
    let process = get_process(pid)?;
    check_signal_perm(&process, ctx, signal.map(|s| s.num()))?;
    process.enqueue_signal(signal.unwrap_or_default());
}

// signal/mod.rs
pub fn handle_pending_signal(user_ctx: &mut UserContext, ctx: &Context, pre_syscall_ret: Option<usize>) {
    let Some((signal, sig_action)) = dequeue_pending_signal(ctx) else { return; };
    let sig_num = signal.num();
    match sig_action {
        SigAction::User { handler_addr, flags, restorer_addr, mask } => {
            // Restart syscall if SA_RESTART, setup stack/ucontext/fpu
            handle_user_signal(ctx, sig_num, handler_addr, flags, restorer_addr, mask, user_ctx, signal.to_info())?;
        }
        // ... Dfl/Ign handling (term/stop/cont)
    }
}

pub fn handle_user_signal(/* ... */) -> Result<()> {
    // Write siginfo_t/ucontext_t to stack, clone/reset FPU, set IP/SP/args (sig_num, siginfo_addr, ucontext_addr)
    // Use alternate stack if SA_ONSTACK, block signals in mask
}
```
- Permission checks (euid/suid/cap KILL), enqueue/dequeue signals, user handler setup (stack/ucontext/fpu/args), default actions (kill/stop).

### POSIX Threads (`kernel/src/process/posix_thread/mod.rs`)
```rust
pub struct PosixThread {
    process: Weak<Process>,
    tid: AtomicU32,
    name: Mutex<ThreadName>,
    credentials: Credentials,
    fs: RwMutex<Arc<ThreadFsInfo>>,
    file_table: Mutex<Option<RoArc<FileTable>>>,
    sig_mask: AtomicSigMask,
    sig_queues: SigQueues,
    signalled_waker: SpinLock<Option<Arc<Waker>>>,
    prof_clock: Arc<ProfClock>,
    virtual_timer_manager: Arc<TimerManager>,
    prof_timer_manager: Arc<TimerManager>,
    io_priority: AtomicU32,
    ns_proxy: Mutex<Option<Arc<NsProxy>>>,
}

pub fn enqueue_signal(&self, signal: Box<dyn Signal>) {
    self.sig_queues.enqueue(signal);
    self.wake_signalled_waker();
}

pub fn allocate_posix_tid() -> Tid {
    let tid = POSIX_TID_ALLOCATOR.fetch_add(1, Ordering::SeqCst);
    if tid >= PID_MAX { warn!("PID overflow"); }
    tid
}
```
- Per-thread state (cred/fs/sig/timer/ns), signal waking, TID allocation (up to PID_MAX = u32::MAX/2).

### Process Table (`kernel/src/process/process_table.rs`)
```rust
static PROCESS_TABLE: Mutex<ProcessTable> = Mutex::new(ProcessTable::new());
pub struct ProcessTable {
    inner: BTreeMap<Pid, Arc<Process>>,
    subject: Subject<PidEvent>,
}

pub fn get_process(pid: Pid) -> Option<Arc<Process>> { PROCESS_TABLE.lock().get(pid).cloned() }
pub fn insert(&mut self, pid: Pid, process: Arc<Process>) { self.inner.insert(pid, process); }
pub fn remove(&mut self, pid: Pid) {
    self.inner.remove(&pid);
    self.subject.notify_observers(&PidEvent::Exit(pid));
}
```
- BTreeMap for PID/process mapping, observers for PidEvent::Exit; similar for GROUP_TABLE/SESSION_TABLE.

### Credentials (`kernel/src/process/credentials/mod.rs`)
```rust
pub struct Credentials<R = FullOp>(Arc<Credentials_>, R); // R: FullOp/ReadOp/WriteOp
// Supports UID/GID (real/effective/saved/fs/supplementary), capabilities (CapSet)
```
- Arc-wrapped credentials with operation restrictions; set_from_elf for suid/sgid.

### Namespaces (`kernel/src/process/namespace/mod.rs`)
```rust
pub(super) mod nsproxy; // NsProxy
pub(super) mod unshare;
pub(super) mod user_ns; // UserNamespace
// clone_ns_proxy(new_clone flags), unshare for NS isolation
```
- Proxy for thread namespaces, unshare for clone-time isolation, user_ns for capability mapping.

### Program Loader (`kernel/src/process/program_loader/mod.rs`)
```rust
pub struct ProgramToLoad {
    elf_file: Path,
    file_first_page: Box<[u8; PAGE_SIZE]>,
    argv: Vec<CString>,
    envp: Vec<CString>,
}

pub fn build_from_file(elf_file: Path, fs_resolver: &FsResolver, argv: Vec<CString>, envp: Vec<CString>, recursion_limit: usize) -> Result<Self> {
    if let Some(new_argv) = parse_shebang_line(&*file_first_page)? {
        return Self::build_from_file(interpreter, fs_resolver, new_argv, envp, recursion_limit - 1);
    }
    // Parse ELF headers, check_executable
}

pub fn load_to_vmar(/* ... */) { /* load_elf_to_vmar */ }
```
- Handles ELF loading and shebang interpretation (recursion limit to prevent loops).

### Process VM (`kernel/src/process/process_vm/mod.rs`)
```rust
pub struct ProcessVm {
    init_stack: InitStack,
    heap: Heap,
    #[cfg(target_arch = "riscv64")] vdso_base: AtomicUsize,
}

pub fn map_and_write_init_stack(&self, vmar: &Vmar, argv: Vec<CString>, envp: Vec<CString>, aux_vec: AuxVec) -> Result<()> {
    self.init_stack.map_and_write(vmar, argv, envp, aux_vec)
}

pub(super) fn unshare_and_renew_vmar(ctx: &Context, vmar: &mut ProcessVmarGuard) {
    let new_vmar = Vmar::new();
    // Activate, set in thread_local/process, map heap
}

pub struct ProcessVmarGuard<'a> { inner: MutexGuard<'a, Option<Arc<Vmar>>> }
// unwrap/as_ref/set_vmar/dup_vmar/init_stack_reader
```
- Manages initial stack (auxv/argv/envp), heap (brk alloc), vDSO base (riscv64); guards VMAR for unshare/renew.

## Architecture and Patterns

- **Lifecycle Flow**: Init (spawn_init_process) -> Clone (flags determine sharing: VM/FS/files/sighand/ns) -> Exec (load ELF/shebang, renew VMAR/stack/heap/auxv, apply caps/reset sigs/files) -> Run (enqueue_signal, handle_pending: dequeue/mask/ignore -> user handler (stack/ucontext/fpu/args) or default (term/stop)) -> Exit (zombie, drop vmar/pidfile, notify/reaper orphans) -> Kill/Wait (perm check/enqueue, waitpid/reap stats).
- **State Management**: Arc<Process> with Mutex<RwLock> for vmar/tasks/children/sig_dispositions/queues/timer/user_ns; Atomic for nice/oom_adj/signals; BTreeMap<Pid,Arc<Process>> in global table with PidEvent observers for exit notifications.
- **Concurrency**: SpinLock/Mutex for signalled_waker/file_table, AtomicSigMask for blocking, WaitQueue for children, disable_preempt for vmar renew.
- **Security**: Cred checks (euid==suid or cap KILL), unshare for ns/fs/files isolation, apply_caps post-exec.
- **POSIX Compliance**: Sigaction (user/dfl/ign, SA_RESTART/RESTORER/SIGINFO/ONSTACK/NODEFER/RESETHAND), pthread (tid alloc, robust lists, futex), clone/execve/exit/kill/waitid, rlimits, prof/virtual timers.
- **Patterns**: Delegation (Signal trait, enqueue/dequeue/handle), Event-driven (PidEvent, waker for signals), Copy-on-write (fork_from for vm/stack/heap), Guard patterns (ProcessVmarGuard for vmar access).

## Integration

- **Syscalls**: clone/execve/exit/kill/waitpid/waitid/signal/sigaction/sigprocmask/sigaltstack/setuid/setgid/capset, integrated via syscall table.
- **Threading**: AsPosixThread trait, PosixThreadBuilder for pthread_create, do_exit_group for thread cleanup.
- **Time**: ProfClock/VirtualTimerManager for ITIMER_PROF/VIRTUAL, process_expired_timers.
- **FS**: ThreadFsInfo/RwMutex<Arc<ThreadFsInfo>>, unshare_close_files, file_table dup/share.
- **VM**: Vmar renew/map for exec/unshare, init_stack reader for auxv, heap brk/sbrk.
- **Creds/NS**: set_uid_from_elf post-load, unshare_ns_proxy for clone, UserNamespace cap mapping.
- **Other**: Cgroup for resource control, oom_score_adj for OOM killer, sig_dispositions shared across threads.

## WEB3.ARL Ties

- **Secure Isolation**: Namespaces (user_ns/unshare) and capabilities (CapSet::KILL) enable AR containerization, isolating dynamic AR tasks (clone/exec) with secure mounts/comms.
- **Signals as Events**: Enqueue/dequeue for AR event handling (e.g., SIGUSR1 for AR protocol triggers), async wakers for low-latency AR responses.
- **Process Lifecycle for AR Tasks**: Clone for AR thread spawning, exec for loading AR binaries (ELF with caps), exit/reaper for cleanup, kill/perm for secure termination.
- **ABI Preservation**: POSIX-compliant signals/creds/ns ensure portable AR apps; secure checks prevent privilege escalation in AR environments.

## Testing and TODOs

- **Existing**: Integration tests in osdk/tests (e.g., clone/execve signal handling, pid allocation).
- **TODOs**:
  - Full clone flags support (e.g., CLONE_NEWUSER, CLONE_NEWPID - currently unsupported/warn).
  - Signal testing: Dequeue/mask/ignore edge cases, user handler failures (SIGSEGV), SA_RESETHAND reset.
  - NS/Creds: Complete user_ns mapping, unshare perf, cap inheritance post-exec.
  - Loader: Shebang recursion limits/depth validation, ELF parsing errors (invalid headers).
  - VM: Stack overflow detection, heap brk/sbrk races, vDSO loading (riscv64).
  - Batch/Deadline Sched Ties: Integrate with sched/ for AR low-latency (RT policy).
  - PID Wraparound: Recycle small PIDs on overflow (PID_MAX).
  - Robustness: Zombie reaper races, signal propagation across ns, OOM with cgroup limits.

## Notes

- **Secure ABI**: Preserve POSIX semantics for signals/creds (e.g., euid checks, cap KILL); no leaks in unshare/renew.
- **Licensing**: MPL-2.0; attribute AGL owners in docs.
- **Migration**: Gitbook-friendly Markdown; SEO keywords (process management, POSIX threads, signal handling, namespaces, ELF loader, virtual memory layout).
- **Guidance**: For AR integrations, prioritize ns/caps for isolation; test signal latency for real-time AR events.
