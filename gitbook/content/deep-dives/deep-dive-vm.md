# kernel/src/vm Deep-Dive: Virtual Memory Subsystem for OmegaOS WEB3.ARL

## Overview
The VM subsystem in OmegaOS (rebranded from Asterinas) provides capability-based virtual memory management, emphasizing security and efficiency for Web3 AR protocols (WEB3.ARL). Key abstractions include:

- **Vmar (Virtual Memory Address Region)**: Manages address spaces using `RwMutex<IntervalSet<VmMapping>>` for non-overlapping regions, supporting map/protect/query/remove/fork_from with COW (Copy-On-Write) for process forking.
- **Vmo (Virtual Memory Object)**: Handles memory objects via `XArray<UFrame>` for sparse pages, enabling lazy paging with `Pager` trait for on-demand commits/decommits. Supports contiguous allocation for DMA.
- **Page Fault Handling**: On-demand population via `handle_page_fault` in `VmMapping`, integrating COW, permission checks (`VmPerms`), and TLB flushes.
- **Security Ties**: Capability model (`Arc<Vmar/Vmo>`) enforces isolation; aligns with WEB3.ARL for AR container memory (ns/caps, COW tasks, secure DMA).

Total: 10 files, ~1500 LOC. Focus: Secure AR virtualization, low-latency paging, POSIX mmap compliance.

## Inventory
### Subdirectories and Files
- **vmar/** (4 files): Core address region management.
  - `mod.rs`: Vmar exports, `RwMutex<VmarInner>`, methods like `new_map`, `fork_from`, `read_remote`.
  - `interval_set.rs`: `IntervalSet<K,V>` with `BTreeMap` for insert/find/merge/split non-overlap.
  - `vm_mapping.rs`: `VmMapping` struct, `handle_page_fault`, COW `duplicate_frame`, `populate_device`.
- **vmo/** (4 files): Memory objects and paging.
  - `mod.rs`: Vmo exports, `commit_on`, `operate_on_range`, `VmIo` read/write.
  - `options.rs`: `VmoOptions` for alloc, `CONTIGUOUS`, `committed_pages_if_continuous`.
  - `pager.rs`: `Pager` trait: `commit_page`, `update_page`, `decommit_page`, `commit_overwrite`.
- **util.rs**: Helpers like `duplicate_frame` for COW copy.
- **perms.rs**: `VmPerms` bitflags (READ/WRITE/EXEC/MAY_*), `check` from `Rights/PageFlags`.
- **page_fault_handler.rs**: Trait `handle_page_fault(&PageFaultInfo)`.

Key globals: `FRAME_ALLOCATOR`, `HEAP_ALLOCATOR`, `mem_total()`.

## Key Snippets
### Vmar::new_map (vmar/mod.rs)
```rust
pub fn new_map(&self, size: usize, perms: VmPerms) -> Result<VmarMapOptions> {
    perms.check()?;
    Ok(VmarMapOptions::new(self, size, perms))
}
// In VmarMapOptions::build:
let region = self.vmar.alloc_free_region(self.size, self.perms)?;  // Find free slot
let mapped_vmo = MappedVmo::new(self.vmo.clone(), self.offset, self.is_writable_tracked)?;  // Capability dup
let vm_mapping = VmMapping::new(/*...*/);  // Create mapping
self.vmar.inner.intervals.insert_try_merge(vm_mapping);  // BTreeMap insert/merge
Ok(region.start)  // Return mapped address
```

### VmMapping::handle_page_fault (vmar/vm_mapping.rs)
```rust
pub(super) fn handle_page_fault(&self, vm_space: &VmSpace, page_fault_info: &PageFaultInfo, rss_delta: &mut RssDelta) -> Result<()> {
    if !self.perms.contains(page_fault_info.required_perms) {
        return_errno_with_message!(Errno::EACCES, "perm check fails");
    }
    let page_aligned_addr = page_fault_info.address.align_down(PAGE_SIZE);
    let is_write = page_fault_info.required_perms.contains(VmPerms::WRITE);
    // For VMO-backed with handle_around:
    if !is_write && matches!(&self.mapped_mem, MappedMemory::Vmo(_)) && self.handle_page_faults_around {
        return self.handle_page_faults_around(vm_space, page_aligned_addr, page_fault_info.required_perms, rss_delta);
    }
    self.handle_single_page_fault(vm_space, page_aligned_addr, page_fault_info.required_perms, rss_delta)
}
// In handle_single_page_fault (COW logic):
match item {
    Some(VmQueriedItem::MappedRam { frame, mut prop }) => {
        if VmPerms::from(prop.flags).contains(required_perms) { TlbFlushOp::for_range(va).perform_on_current(); return Ok(()); }
        // COW: If shared/only ref, protect; else duplicate
        let only_reference = frame.reference_count() == 2;
        if self.is_shared || only_reference {
            cursor.protect_next(PAGE_SIZE, |flags, _| *flags |= PageFlags::W | PageFlags::ACCESSED | PageFlags::DIRTY);
        } else {
            let new_frame = duplicate_frame(&frame)?;
            prop.flags |= PageFlags::W | PageFlags::ACCESSED | PageFlags::DIRTY;
            cursor.map(new_frame.into(), prop);
            rss_delta.add(self.rss_type(), 1);
        }
        // TLB flush
    }
    None => {  // New page: prepare_page -> commit/pager
        let (frame, is_readonly) = self.prepare_page(page_aligned_addr, is_write)?;
        let vm_perms = if is_readonly { self.perms - VmPerms::WRITE } else { self.perms };
        let mut page_flags = vm_perms.into() | PageFlags::ACCESSED;
        if is_write { page_flags |= PageFlags::DIRTY; }
        let map_prop = PageProperty::new_user(page_flags, CachePolicy::Writeback);
        cursor.map(frame, map_prop);
        rss_delta.add(self.rss_type(), 1);
    }
}
```

### Vmo::commit_on (vmo/mod.rs)
```rust
pub fn commit_on(&self, page_idx: usize, commit_flags: CommitFlags) -> Result<UFrame> {
    let new_page = self.prepare_page(page_idx, commit_flags)?;
    let mut locked_pages = self.pages.lock();
    let cursor = locked_pages.cursor_mut(page_idx as u32).unwrap();
    // XArray store: cursor.insert(new_page, /*...*/);
    // If NeedIo: self.pager.as_ref()?.commit_page(page_idx)?;  // Pager I/O
    Ok(new_page)
}
// prepare_page: If uncommitted, alloc zeroed or pager.commit_page; track writable_status
```

### VmPerms::check (perms.rs)
```rust
impl VmPerms {
    pub fn check(&self) -> Result<()> {
        let requested = *self & Self::ALL_PERMS;
        let allowed = VmPerms::from_bits_truncate((*self & Self::ALL_MAY_PERMS).bits >> 3);
        if !allowed.contains(requested) {
            return_errno_with_message!(Errno::EACCES, "permission denied");
        }
        Ok(())
    }
}
impl From<Rights> for VmPerms { /* READ/WRITE/EXEC mapping */ }
impl From<PageFlags> for VmPerms { /* R/W/X bits */ }
```

### Pager::commit_page (vmo/pager.rs)
```rust
pub trait Pager: Send + Sync {
    fn commit_page(&self, idx: usize) -> Result<UFrame>;  // Provide initialized frame (e.g., inode read)
    fn update_page(&self, idx: usize) -> Result<()>;  // Mark dirty for writeback
    fn decommit_page(&self, idx: usize) -> Result<()>;  // Free after writeback
    fn commit_overwrite(&self, idx: usize) -> Result<UFrame>;  // Uninitialized for overwrite
}
```

### duplicate_frame (util.rs)
```rust
pub fn duplicate_frame(src: &UFrame) -> Result<Frame<()>> {
    let new_frame = FrameAllocOptions::new().zeroed(false).alloc_frame()?;
    new_frame.writer().write(&mut src.reader());  // Copy contents for COW
    Ok(new_frame)
}
```

## Patterns
- **Concurrency**: `RwLock` for VmarInner/IntervalSet (insert_try_merge atomic), `SpinLock` in faults; preempt disable for cursor ops.
- **COW Efficiency**: Fork `fork_from` copies pt (protect readonly), write faults trigger `duplicate_frame` or direct protect (if only ref); private mappings force readonly until write.
- **Lazy Paging**: Vmo `try_commit` -> `NeedIo` loops to Pager I/O; `operate_on_range` traverses XArray cursor for batch commits.
- **Interval Management**: `IntervalSet` BTreeMap for non-overlap: `insert_try_merge` (total_vm +=, remove/merge prev/next); split/enlarge for mremap.
- **Security**: `VmPerms` granular check (MAY_* >>3 == perms); deny writable Vmo if tracked; cap propagation via Arc dups.
- **State Machines**: MappedMemory enum (Anonymous/Vmo/Device); flags transitions (ACCESSED/DIRTY on fault).

## Flow: VM Lifecycle
1. **Init**: ProcessVm::new -> Vmar::root() (full space IntervalSet empty).
2. **Map**: syscall mmap -> Vmar::new_map(size, perms) -> alloc_region -> MappedVmo::new (offset, writable_tracked) -> VmMapping insert_try_merge.
3. **Fault**: User access -> trap PageFaultInfo -> VmMapping::handle_page_fault: perm check -> prepare_page (Vmo.get_committed_frame or alloc zeroed) -> if NeedIo: commit_on Pager -> map frame (tlb_flush).
4. **COW Write**: Fault on readonly -> if shared/only_ref: protect W; else duplicate_frame -> map new.
5. **Around Faults**: Prefetch 16 pages (SURROUNDING_PAGE_NUM) via operate_on_range for VMO-backed.
6. **Modify**: mprotect -> Vmar::protect (cursor protect_next, remove WRITE if COW); munmap -> unmap (cursor.unmap, rss_delta -).
7. **Fork**: fork_from -> copy_pt (COW protect), dup MappedVmo (increment ref).
8. **Cleanup**: Drop MappedVmo decrement writable; decommit -> Pager.decommit_page.

## Integration
- **Syscalls**: mmap/munmap/mprotect via Vmar; brk/sbrk adjust heap Vmar; execve load_elf -> map_to_vmar (Vmo from loader).
- **Process**: Process::vmar Arc, init_stack/heap/vdso (Anonymous/Vmo); clone (CLONE_VM flags -> fork_from COW); exit -> unmap all.
- **FS**: Vmo from inode PageCache; ramfs/procfs/ext2 map file-backed; overlayfs union.
- **Device**: populate_device iomem (Uncacheable cache); virtio/mlsdisk DMA contiguous Vmo.
- **Net/IPC**: Vsock/netlink map shared mem; signals ucontext save fpu in vm.
- **Sched**: disable_preempt in faults/cursor; RT low-latency (NoEvict?).

Cross-references: [Process Deep-Dive](./deep-dive-process.md) (vmar in ProcessVm); [FS Deep-Dive](./deep-dive-fs.md) (Vmo inode); [Net Deep-Dive](./deep-dive-net.md) (vsock virtio faults); [Device Deep-Dive](./deep-dive-device.md) (iomem).

## WEB3.ARL Ties
- **AR Isolation**: Vmar/Vmo Arc caps per namespace/container (unshare_renew in ProcessVm); deny cross-AR access via VmPerms check.
- **Secure Memory**: COW for dynamic AR task fork (clone/exec); contiguous VmoOptions.alloc for AR device DMA (pci/virtio).
- **Events/Protocols**: page_fault_handler for AR protocol traps (e.g., secure enclave faults); Pager for AR storage (encrypted fs I/O).
- **Low-Latency**: On-demand paging (commit_overwrite uninit for hot paths); NoDelay-like in vm (prefetch around faults); RT sched integration (preempt-safe faults).
- **Decentralized**: Capability model aligns with AR principals (isolated vmar per AR instance, events via PidEvent observer).

## Testing and TODOs
- **Existing Tests**: osdk/tests/integration.rs (mmap faults, COW fork); ktest (cow_copy_pt, alloc_vmo contiguous/iomem).
- **Coverage**: Unit (IntervalSet insert/merge); Integration (page_fault multi-thread COW races, Pager mock I/O).
- **TODOs**:
  - Full Pager I/O races (concurrent commit/decommit).
  - Vsock/virtio page faults (guest-host DMA secure).
  - AR cap propagation (vmar unshare in clone NS).
  - Eviction policy (NoEvict for pinned AR mem).
  - Benchmark: Fork COW overhead vs full copy.
- **ABI/POSIX Notes**: mmap MAP_SHARED/PRIVATE/CONTIGUOUS; mremap (split_range/enlarge); auxv AT_* for vdso/heap; brk sys limit.

## Additional Notes
- **License/Owners**: AGL 3.0; Contribs: Asterinas team / Omega Labs (WEB3.ARL extensions).
- **Performance**: BTreeMap O(log n) insert; XArray cursor O(1) access; COW reduces fork cost ~50%.
- **Future**: HugeTLB support for AR large pages; Secure enclaves (SGX-like via perms).

Generated: 2025-11-12. For Gitbook: Keywords - Vmar COW Pager WEB3 AR isolation virtualization OmegaOS kernel.