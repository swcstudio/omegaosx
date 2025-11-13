// SPDX-License-Identifier: MPL-2.0

pub mod iface;
pub mod socket;
mod uts_ns;

pub use uts_ns::UtsNamespace;

pub fn init() {
    iface::init();
    socket::netlink::init();
    socket::vsock::init();
}

/// Lazy init should be called after spawning init thread.
    pub fn init_in_first_kthread() {
        iface::init_in_first_kthread();
    }
}

/// Prototype P2P mesh sync stub for WEB3.ARL.
/// Integrates with omega-bigtcp for low-latency gossip in AR containers.
pub fn p2p_sync() -> Result<()> {
    log::info!("P2P mesh sync stub: Enabling low-latency WEB3.ARL hooks via omega-bigtcp");
    // TODO: Implement gossip protocol, peer discovery, and AR-specific routing
    Ok(())
}
