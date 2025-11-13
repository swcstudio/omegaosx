# kernel/comps Deep-Dive: Modular Components for OmegaOS WEB3.ARL

## Overview
The comps/ directory in OmegaOS W3.x (rebranded from Asterinas) provides modular kernel components for hardware drivers and subsystems, enabling hot-plug and extensible support for devices like virtio, pci, network, block, input, framebuffer, and time. Total: 153 files, ~10k LOC. Focus: Component-based architecture using comp-sys for init/register, tying to WEB3.ARL via secure modular AR peripherals (e.g., virtio for guest isolation, pci for DMA caps).

## Inventory
### Subdirectories and Files
- **virtio/** (40+ files): Virtio transport (pci/mmio/bus/arch), devices (socket/network/input/console/block), queue/dma_buf. Key: lib.rs exports, transport/pci/mod.rs (msix/legacy/driver), device/network/mod.rs (header/device/config), transport/mmio/driver/device.
- **time/** (10 files): Clocksource (tsc/clocksource), RTC (cmos/goldfish/loongson). Key: lib.rs, tsc.rs (init_clock/timer), rtc/mod.rs (Driver trait/init_rtc_driver).
- **systree/** (10 files): SysTree for config (node/tree/attr/utils). Key: lib.rs, node.rs (SysBranchNode/SysLeafNode init_parent), tree.rs (SINGLETON init).
- **softirq/** (8 files): Softirq handling (taskless/stats/softirq_id/lock). Key: lib.rs, taskless.rs (init/process_pending).
- **pci/** (20 files): PCI bus (bus/common_device/cfg_space/capability/arch). Key: lib.rs (init_component), bus.rs (register_driver/probe), cfg_space.rs (BARs).
- **network/** (5 files): Network driver (driver/dma_pool/buffer). Key: lib.rs (register_device/callbacks), dma_pool.rs (init_size).
- **mlsdisk/** (50+ files): MLS disk layers (os/layers 0-bio to 5-disk, tx/util). Key: lib.rs (init_component/create), layers/0-bio/mod.rs (BlockId).
- **logger/** (4 files): Logging (console/aster_logger). Key: lib.rs (init_component).
- **keyboard/** (5 files): i8042 (chip/controller/keyboard). Key: lib.rs (init_component), i8042_chip/mod.rs (init).
- **input/** (6 files): Input core (input_dev/input_handler/event_type_codes). Key: lib.rs (register_device/handler_class).
- **framebuffer/** (7 files): FB (pixel/framebuffer/console_input/console/ansi_escape). Key: lib.rs (init_component), console.rs (register_callback).
- **console/** (3 files): Console (mode/font/lib). Key: lib.rs (register_device).
- **block/** (6 files): Block (request_queue/prelude/lib/bio/id/impl_block_device). Key: lib.rs (register_device/bio_segment_pool_init).

Patterns: init_component macro for registration, register_device/driver/callbacks, modular crates with Cargo.toml deps on comp-sys.

## Key Snippets
### Component Init (common in lib.rs)
```rust
use component::{init_component, ComponentInitError};
#[init_component]
fn init() -> Result<(), ComponentInitError> {
    // Register devices/callbacks
    register_device("name".to_string(), Arc::new(Device));
    Ok(())
}
static COMPONENT: Once<Component> = Once::new();
```

### PCI Driver Register (pci/bus.rs)
```rust
pub fn register_driver(&mut self, driver: Arc<dyn PciDriver>) {
    self.drivers.push(driver);
}
impl PciDriver for MyDriver {
    fn probe(&self, device: PciCommonDevice) -> Result<Arc<dyn PciDevice>, (PciDriverProbeError, PciCommonDevice)> {
        // Match and init
        Ok(Arc::new(MyDevice::new(device)))
    }
}
```

### Network Register (network/lib.rs)
```rust
pub fn register_device(name: String, device: Arc<dyn NetDevice>) {
    let table = COMPONENT.get().unwrap().network_device_table.lock();
    table.insert(name, device);
}
pub fn register_recv_callback(name: &str, callback: impl NetDeviceCallback) { /* ... */ }
```

### MLS Disk Create (mlsdisk/lib.rs)
```rust
#[init_component]
fn init() -> Result<(), ComponentInitError> {
    let device = MlsDisk::create(raw_disk, root_key, None)?;
    aster_block::register_device("mlsdisk".to_string(), Arc::new(device));
    Ok(())
}
```

## Patterns
- **Modular Init**: comp-sys init_component macro, Once<Component> for tables (network_device_table RwLock<HashMap>).
- **Registration**: register_device/driver/callback (e.g., PCI probe, network recv/send, input handler_class).
- **Drivers**: Trait PciDriver/NetDeviceCallback/TtyDriver with probe/construct/push_input.
- **Layers**: MLS disk 0-bio (BlockRing) to 5-disk (lsm/compaction), crypto (Aead/RandomInit).
- **Concurrency**: RwLock tables, Atomic status, SpinLock inner.
- **Extensibility**: Arch-specific (pci arch/x86/riscv/loongarch), transport (virtio pci/mmio).

## Flow: Component Lifecycle
1. **Init**: Kernel boot -> comps/mod.rs? Calls init_component per crate (e.g., time::init_rtc_driver, pci::init).
2. **Register**: Probe/bus discover (pci register_common_device, network register_device), add to tables (HashMap name/device).
3. **Operate**: Driver callbacks (push_input for input/fb, bio submit for block/mls, probe for pci/virtio).
4. **Event**: Softirq raise (taskless init/process_pending), input submit_events.
5. **Cleanup**: Drop unregister (input unregister_device), but mostly kernel lifetime.

## Integration
- **Kernel**: comp-sys for all, block::register_device (mls/virtio block), input::register_device (keyboard/fb).
- **Device/FS**: PCI/virtio bus for hardware, systree for config, logger for debug.
- **Process/VM**: Input events to TTY, bio to PageCache, time for sched/clock.
- Cross: [Device Deep-Dive](./deep-dive-device.md) (virtio/pci drivers); [Net Deep-Dive](./deep-dive-net.md) (network comp); [VM Deep-Dive](./deep-dive-vm.md) (dma_buf in virtio).

## WEB3.ARL Ties
- **AR Modularity**: Hot-plug comps for AR peripherals (pci/virtio socket/network for guest AR, input/fb for UI).
- **Secure Drivers**: Crypto in mlsdisk (Aead layers for AR storage), TDX? in comps for enclaves.
- **Events**: Softirq for AR protocol interrupts, callbacks for low-latency (network recv).
- **Isolation**: Component tables per-cpu/irq-safe, caps in drivers (e.g., dma_pool for secure alloc).

## Testing and TODOs
- **Existing**: mlsdisk ktests (layers/tx), virtio tests? (queue/dma).
- **TODOs**: Full units (pci probe, network callbacks), integration (hot-plug virtio AR device), AR-specific (secure dma in comps).
- **Notes**: POSIX driver model (register/probe), ABI for callbacks.

Generated: 2025-11-12. Keywords: modular comps virtio pci WEB3 AR drivers OmegaOS.
