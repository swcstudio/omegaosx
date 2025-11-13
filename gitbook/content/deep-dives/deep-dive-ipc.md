# kernel/src/ipc Deep-Dive

## Overview
The IPC (Inter-Process Communication) subsystem in OmegaOS provides synchronization primitives, primarily focusing on System V semaphores with stubs for POSIX. It supports key-based creation, atomic operations, and pending/wait mechanisms for secure coordination. Total: 6 files, ~800 LOC. Emphasis on WEB3.ARL: Semaphores enable secure locking for AR protocol messaging and shared state in decentralized environments (e.g., sync access to shared memory for AR data streams).

Generated: 2025-11-12

## Inventory and Subdir Summaries
- **mod.rs** (Core types/init): Defines key_t, IpcFlags (IPC_CREAT/EXCL/NOWAIT/SEM_UNDO), IpcControlCmd (RMID/SET/STAT/SEM_*), IpcPermission (key/uid/gid/cuid/cguid/mode). Init calls semaphore::init_in_first_kthread().
- **semaphore/mod.rs** (Semaphore entry): Submodules posix/ (stub), system_v/. Init system_v.
- **semaphore/system_v/mod.rs** (System V perms): (Inferred) Permission handling, constants.
- **semaphore/system_v/sem_set.rs** (Sem sets): SemaphoreSet (nsems, inner SpinLock<SemSetInner: sems Box<Semaphore>, pending_alter/const LinkedList<PendingOp>>, permission, ctime/otime). Functions: create_sem_set, check_sem, sem_sets access (RwLock<BTreeMap<key_t, SemaphoreSet>>). Constants: SEMMNI=32000, SEMMSL=32000, SEMOPM=500, SEMVMX=32767. Init ID_ALLOCATOR.
- **semaphore/system_v/sem.rs** (Sem ops): SemBuf (sem_num/op/flags), Status (Normal/Pending/Removed AtomicU16), PendingOp (sops Vec, status Arc<AtomicStatus>, waker, pid). Semaphore (val i32, latest_modified_pid Pid). sem_op: Atomic perform, pending/wait/wake with timeout. Helpers: do_smart_update (wake alter/const), perform_atomic_semop (zero/neg/overflow checks, apply ops).
- **semaphore/posix/mod.rs** (POSIX stub): Empty implementation placeholder.

No pipe/shm/msg/signal yet; focus on semaphores. Patterns: AtomicStatus for op state, SpinLock/RwLock for inner/sets, Waiter/Waker for async pending, LinkedList<BTreeMap for queues/IDs.

## Key Snippets
### Types and Structures (mod.rs)
```rust
#[expect(non_camel_case_types)]
pub type key_t = i32;

bitflags! {
    pub struct IpcFlags: u32 {
        const IPC_CREAT = 1 << 9;
        const IPC_EXCL = 1 << 10;
        const IPC_NOWAIT = 1 << 11;
        const SEM_UNDO = 1 << 12;
    }
}

#[derive(Debug)]
pub struct IpcPermission {
    key: key_t, uid: Uid, gid: Gid, cuid: Uid, cgid: Gid, mode: u16,
}
```

### SemaphoreSet (sem_set.rs)
```rust
#[derive(Debug)]
pub struct SemaphoreSet {
    nsems: usize,
    inner: SpinLock<SemSetInner>,
    permission: IpcPermission,
    sem_ctime: AtomicU64,
    sem_otime: AtomicU64,
}

pub(super) struct SemSetInner {
    pub(super) sems: Box<[Semaphore]>,
    pub(super) pending_alter: LinkedList<PendingOp>,
    pub(super) pending_const: LinkedList<PendingOp>,
}
```

### PendingOp and sem_op (sem.rs)
```rust
pub(super) struct PendingOp {
    sops: Vec<SemBuf>,
    status: Arc<AtomicStatus>,
    waker: Option<Arc<Waker>>,
    pid: Pid,
}

pub fn sem_op(sem_id: key_t, sops: Vec<SemBuf>, timeout: Option<Duration>, ctx: &Context) -> Result<()> {
    // ... create pending_op, get alter/dupsop flags
    let sem_set = sem_sets().get(&sem_id).ok_or(Error::new(Errno::EINVAL))?;
    let mut inner = sem_set.inner();
    if perform_atomic_semop(&mut inner.sems, &mut pending_op)? {
        // success, smart update wakes
        return Ok(());
    }
    // wait with waiter, on wake check status
}
```

### perform_atomic_semop (sem.rs)
```rust
fn perform_atomic_semop(sems: &mut Box<[Semaphore]>, pending_op: &mut PendingOp) -> Result<bool> {
    let mut result;
    for op in pending_op.sops_iter() {
        let sem = sems.get(op.sem_num as usize).ok_or(Errno::EFBIG)?;
        let flags = IpcFlags::from_bits_truncate(op.sem_flags as u32);
        result = sem.val();
        if op.sem_op == 0 && result != 0 { /* zero cond */ }
        result += i32::from(op.sem_op);
        if result < 0 { /* neg, wait or EAGAIN */ }
        if result > SEMVMX { return_errno!(Errno::ERANGE); }
    }
    // apply
    for op in pending_op.sops_iter() {
        if op.sem_op != 0 {
            let sem = &mut sems[op.sem_num as usize];
            sem.val += i32::from(op.sem_op);
            sem.latest_modified_pid = pending_op.pid;
        }
    }
    Ok(true)
}
```

## Architecture and Patterns
- **Atomic Operations**: perform_atomic_semop checks all sops atomically (zero/neg/overflow), applies if valid. Uses SpinLock for inner consistency.
- **Pending Management**: LinkedList<PendingOp> for alter (op!=0) and const (op=0 zero-wait). do_smart_update wakes compatible ops post-change (e.g., wake_const_ops on zero).
- **Async Waiting**: Waiter/Waker pairs, optional JIFFIES timeout. Status AtomicU16 for Normal/Pending/Removed.
- **ID Allocation**: IdAlloc for sem IDs (1..SEMMNI), BTreeMap<key_t, SemSet>.
- **Cleanup**: Drop SemSet wakes/clears pending with Removed status.
- **Limits/Errors**: SEMVMX/ERANGE, EFBIG (num), EAGAIN (wait/nowait), EIDRM (removed), EINVAL (id/nsems).

## State Flow Graph
1. semop(sem_id, sops, timeout): Create PendingOp (Pending status).
2. perform_atomic: Simulate/apply all sops -> if fail, push to pending_alter/const, wait.
3. On change (setval/semop success): do_smart_update -> check/wake compatible pending (e.g., if new val=0, wake const ops).
4. Wake: Set Normal, waker.wake_up() -> waiter returns, check status (Normal=ok, Removed=EIDRM, Pending=EAGAIN/retry).
5. Exit/Drop: Wake all with Removed.

## Integration and WEB3.ARL Ties
- Syscalls: Hooks for semget/semctl/semop (not in src/ipc, likely syscall/mod.rs).
- Process: Pid tracking, credentials for perm (stubbed).
- WEB3.ARL: Semaphores for secure AR comm (e.g., lock shared shm for AR data packets, atomic ops prevent race in decentralized sync). Extend for msg queues in AR pub/sub.
- Related: fs/ for shm files, vm/ for attach, process/ for exit undo (TODO).

## Testing and TODOs
- Units: Add tests for semop edge (zero/neg/timeout/multi-sop), setval wake.
- Errors: Implement full perm check (warn now), SEM_UNDO (pending adjust on exit).
- Expand: Implement pipe/shm/msg/signal for full POSIX/System V.
- Graph: Visualize flow (e.g., Mermaid: semop --> perform --> wait? --> wake --> status).

## Notes and Guidance
- Secure: No unsafe, atomic wrappers. For AR: Use sem for protocol handshakes.
- Preserve ABI: Match Linux semid_ds/IpcPerm layout.
- Next: Implement posix/sem_t for pthread compat.