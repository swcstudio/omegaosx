# kernel/src/sched Deep-Dive

## Overview
The scheduler implements a multi-class Completely Fair Scheduler (CFS) with real-time (RT), fair (CFS), idle, and stop classes. Supports policies (SCHED_FIFO/RR, CFS nice, idle), priority-based enqueue/pick_next, vruntime balancing for fairness, and per-CPU runqueues with SpinLock. Total: 12 files, ~1200 LOC. WEB3.ARL focus: Real-time priorities for AR protocol tasks (e.g., low-latency comm), secure preemption/locks for decentralized AR execution.

Generated: 2025-11-12

## Inventory and Subdir Summaries
- **mod.rs**: Entry (nice, sched_class, stats exports: init/inject_scheduler, SchedPolicy/Attr, nr_queued_and_running).
- **nice.rs**: Nice values (-20..19), AtomicNice, weight calc (1.25^(-nice)).
- **sched_class/mod.rs**: Core (ClassScheduler: per-CPU SpinLock<PerCpuClassRqSet>, SchedAttr: policy/real_time/fair, SchedClassRq trait: enqueue/len/pick_next/update_current). Init: inject_scheduler, set_stats. Enqueue: select_cpu (affinity/load), policy-based rq dispatch. Pick_next: hierarchy (stop>rt>fair>idle).
- **sched_class/policy.rs**: SchedPolicy (Stop/RealTime{Fifo/RR}/Fair(Nice)/Idle), AtomicSchedPolicyKind, SchedPolicyState (SpinLock policy).
- **sched_class/time.rs**: TSC-based clocks (base_slice_ns=750us, min_period_ns=6ms), factors for ns->clocks.
- **sched_class/real_time.rs**: RT class (prio 1-99, PrioArray: BitArr map + VecDeque queues x100, active/inactive swap). Attr: prio/time_slice (0=FIFO). Enqueue inactive, pick highest prio active/swap. Update: preempt if higher prio or RR slice.
- **sched_class/fair.rs**: CFS fair (vruntime = delta * 1024 / weight, BinaryHeap<Reverse<FairQueueItem>> by vruntime). Attr: AtomicU64 weight/pending_weight/vruntime (HAS_PENDING flag). Enqueue: min_vruntime init, total_weight sum. Pick: pop min vruntime. Update: vruntime += delta*1024/weight, preempt if period_delta > time_slice or vruntime > min + vtime_slice. Period: max(min_period, base_slice * n * log2(1+cpus)).
- **sched_class/idle.rs**: Idle RQ (single entity Option<Arc<Task>>), enqueue only if empty.
- **sched_class/stop.rs**: Stop RQ (single critical task, e.g., reboot), never preempt.
- **stats/mod.rs**: Exports loadavg/scheduler_stats.
- **stats/loadavg.rs**: Load avg calc (fixed-point, RwLock<[LoadAvgFixed;3]>), get_load hook.
- **stats/scheduler_stats.rs**: SchedulerStats trait (nr_queued_and_running), Once global, tick callback.

Patterns: Hierarchy pick_next (stop>rt>fair>idle), SpinLock/LocalIrqDisabled for rq, Atomic for attr/weight, vruntime for CFS fairness, bitarr/heap for RT/efficient pick.

## Key Snippets
### SchedPolicy and Attr (policy.rs, mod.rs)
```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum SchedPolicy {
    Stop,
    RealTime { rt_prio: RealTimePriority, rt_policy: RealTimePolicy },
    Fair(Nice),
    Idle,
}

#[derive(Debug)]
pub struct SchedAttr {
    policy: SchedPolicyState,
    last_cpu: AtomicCpuId,
    real_time: real_time::RealTimeAttr,
    fair: fair::FairAttr,
}
```

### ClassScheduler Enqueue (mod.rs)
```rust
impl Scheduler for ClassScheduler {
    fn enqueue(&self, task: Arc<Task>, flags: EnqueueFlags) -> Option<CpuId> {
        let thread = task.as_thread()?.clone();
        let (still_in_rq, cpu) = { /* select_cpu by affinity/load */ };
        let mut rq = self.rqs[cpu.as_usize()].lock();
        let should_preempt = rq.current.as_ref().is_none_or(|((_, rq_current_thread), _)| {
            thread.sched_attr().policy() < rq_current_thread.sched_attr().policy()
        });
        rq.enqueue_entity((task, thread), Some(flags));
        should_preempt.then_some(cpu)
    }
}
```

### FairAttr Vruntime/Weight (fair.rs)
```rust
#[derive(Debug)]
pub struct FairAttr {
    weight: AtomicU64,
    pending_weight: AtomicU64,
    vruntime: AtomicU64,
}

fn update_vruntime(&self, delta: u64, weight: u64) -> u64 {
    let delta = delta * WEIGHT_0 / weight;
    self.vruntime.fetch_add(delta, Ordering::Relaxed) + delta
}

fn fetch_weight(&self) -> (u64, u64) {
    let mut weight = self.weight.load(Ordering::Acquire);
    if weight & HAS_PENDING == 0 { return (weight, weight); }
    // compare_exchange_weak loop to apply pending
}
```

### FairClassRq Enqueue/Pick/Update (fair.rs)
```rust
impl SchedClassRq for FairClassRq {
    fn enqueue(&mut self, entity: Arc<Task>, flags: Option<EnqueueFlags>) {
        let fair_attr = &entity.as_thread().unwrap().sched_attr().fair;
        let vruntime = match flags { Some(EnqueueFlags::Spawn) => self.min_vruntime + self.vtime_slice(), _ => self.min_vruntime };
        let (_old_weight, weight) = fair_attr.fetch_weight();
        let vruntime = fair_attr.vruntime.fetch_max(vruntime, Ordering::Relaxed).max(vruntime);
        self.total_weight += weight;
        self.entities.push(Reverse(FairQueueItem(entity, vruntime)));
    }

    fn pick_next(&mut self) -> Option<Arc<Task>> {
        let Reverse(FairQueueItem(entity, _)) = self.entities.pop()?;
        let sched_attr = entity.as_thread().unwrap().sched_attr();
        let (old_weight, _weight) = sched_attr.fair.fetch_weight();
        self.total_weight -= old_weight;
        Some(entity)
    }

    fn update_current(&mut self, rt: &CurrentRuntime, attr: &SchedAttr, flags: UpdateFlags) -> bool {
        match flags {
            UpdateFlags::Tick | UpdateFlags::Yield | UpdateFlags::Wait => {
                let (_old_weight, weight) = attr.fair.fetch_weight();
                let vruntime = attr.fair.update_vruntime(rt.delta, weight);
                self.min_vruntime = match self.entities.peek() { Some(Reverse(leftmost)) => vruntime.min(leftmost.key()), None => vruntime };
                matches!(flags, UpdateFlags::Wait) || rt.period_delta > self.time_slice(weight) || vruntime > self.min_vruntime + self.vtime_slice()
            }
            UpdateFlags::Exit => !self.is_empty(),
        }
    }
}
```

### RealTimeClassRq (real_time.rs)
```rust
struct PrioArray { map: BitArr![for 100], queue: [VecDeque<Arc<Task>>; 100] }

impl SchedClassRq for RealTimeClassRq {
    fn enqueue(&mut self, entity: Arc<Task>, _: Option<EnqueueFlags>) {
        let prio = entity.as_thread().unwrap().sched_attr().real_time.prio.load(Relaxed);
        self.inactive_array().enqueue(entity, prio);
        self.nr_running += 1;
    }

    fn pick_next(&mut self) -> Option<Arc<Task>> {
        if self.nr_running == 0 { return None; }
        (self.active_array().pop()).or_else(|| { self.swap_arrays(); self.active_array().pop() }).inspect(|_| self.nr_running -= 1)
    }

    fn update_current(&mut self, rt: &CurrentRuntime, attr: &SchedAttr, flags: UpdateFlags) -> bool {
        let attr = &attr.real_time;
        match flags {
            UpdateFlags::Tick | UpdateFlags::Yield => match attr.time_slice.load(Relaxed) {
                0 => self.active_array().peek_prio().is_some() || self.inactive_array().peek_prio().is_some_and(|prio| prio < attr.prio.load(Relaxed)),
                ts => ts <= rt.period_delta && !self.is_empty(),
            },
            UpdateFlags::Wait | UpdateFlags::Exit => !self.is_empty(),
        }
    }
}
```

## Architecture and Patterns
- **Multi-Class Hierarchy**: Pick_next: stop (critical, single) > RT (O(1) prio bitarr/queues, FIFO/RR slice) > Fair/CFS (vruntime BinaryHeap, weight-based fairness) > Idle (single). Enqueue policy-dispatch.
- **Per-CPU RQs**: SpinLock<PerCpuClassRqSet> (irq-disabled), load_stats (queue_len, is_idle). Select_cpu: affinity-min_load round-robin.
- **Fairness (CFS)**: Vruntime accum (delta*1024/weight), min_vruntime normalize, period = max(min_period, base*n*log2(1+cpus)), time_slice = period*weight/total. Pending weight CAS for lock-free update.
- **RT**: Active/inactive PrioArray swap, highest prio pop, preempt if higher prio or RR slice exceed.
- **Atomic/Sync**: AtomicU64 vruntime/weight (Relaxed/AcqRel), SpinLock policy, LocalIrqDisabled rq.
- **Preempt**: Update_current: class-specific (vruntime/time_slice checks), lookahead hierarchy for higher prio.

## State Flow Graph
1. Enqueue(task, flags): Select cpu (affinity/load), dispatch to class RQ (e.g., fair: fetch_weight, vruntime max(min_vr + vslice), push heap, total_weight += w).
2. Pick_next: Hierarchy pick (stop? rt pop highest? fair pop min vr? idle), replace current, enqueue old if needed.
3. Update_current(flags): rt.update(delta), class check (e.g., fair: vr += delta*1024/w, min_vr update, preempt if period_delta > slice or vr > min + vslice), or higher class !empty.
4. Syscalls (sched_setattr): Update policy/attr (nice/prio/slice), pending_weight for fair.
5. Stats: nr_queued_and_running sum per-cpu, loadavg calc.

## Integration and WEB3.ARL Ties
- Syscalls: sched_setattr/setparam for policy/nice/prio, getaffinity. Hooks in thread::AsThread.
- Process/Thread: SchedAttr in Thread, cpu affinity AtomicCpuSet.
- WEB3.ARL: RT for AR real-time (low-latency protocol packets), fair nice for background AR storage sync, secure preemption (no unsafe, atomic ops) for decentralized task isolation. Extend stop for AR critical shutdown.
- Related: process/ (task spawn), cpu/ (per-cpu init), time/ (tsc sched_clock).

## Testing and TODOs
- Units: vruntime calc edges (weight update mid-slice), RT RR slice/preempt, load balance select_cpu.
- Errors: Policy invalid (EINVAL), prio range. Add yield/exit flags tests.
- Expand: Batch fair (SMP), deadline class for AR deadlines, cgroup limits.
- Graph: Mermaid for enqueue->pick->update flow.

## Notes and Guidance
- Secure: Lock-free weight, irq-safe rq. For AR: Set RT prio for comm threads.
- Preserve ABI: Match Linux SchedPolicy/Attr layout.
- Next: Integrate with WEB3.ARL AR task priorities.