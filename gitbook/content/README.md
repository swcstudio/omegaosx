# The OmegaOS W3.x Book

<p align="center">
    <img src="images/logo_en.svg" alt="omegaosx-logo" width="620"><br>
</p>

Welcome to the documentation for OmegaOS W3.x,
an open-source project and community
focused on developing cutting-edge Rust OS kernels for WEB3.ARL.

## Book Structure

This book is divided into five distinct parts:

#### [Part 1: OmegaOS W3.x Kernel](kernel/)

Explore the modern OS kernel at the heart of OmegaOS W3.x.
Designed to realize the full potential of Rust,
OmegaOS W3.x Kernel implements the Linux ABI in a safe and efficient way.
This means it can seamlessly replace Linux,
offering enhanced safety and security for AR protocols.

#### [Part 2: OmegaOS W3.x OSXTD](osxtd/)

The OmegaOS W3.x OSXTD lays down a minimalistic, powerful, and solid foundation
for OS development.
It's akin to Rust's `std` crate
but crafted for the demands of _safe_ Rust OS development.
The OmegaOS W3.x Kernel is built on this very OSXTD.

#### [Part 3: OmegaOS W3.x OSXDK](osxdk/guide/)

The OSXDK is a command-line tool
that streamlines the workflow to 
create, build, test, and run Rust OS projects
that are built upon OmegaOS W3.x OSXTD.
Developed specifically for OS developers,
it extends Rust's Cargo tool to better suite their specific needs.
OSXDK is instrumental in the development of OmegaOS W3.x Kernel.

#### [Part 4: Contributing to OmegaOS W3.x](to-contribute/)

OmegaOS W3.x is in its early stage
and welcomes your contributions!
This part provides guidance
on how you can become an integral part of the OmegaOS W3.x project.

#### [Part 5: Requests for Comments (RFCs)](rfcs/)

Significant decisions in OmegaOS W3.x are made through a transparent RFC process.
This part describes the RFC process
and archives all approvaed RFCs.

## Licensing

OmegaOS W3.x's source code and documentation primarily use the 
[Mozilla Public License (MPL), Version 2.0](https://github.com/swcstudio/omegaosx/blob/main/LICENSE-MPL).
Select components are under more permissive licenses,
detailed [here](https://github.com/swcstudio/omegaosx/blob/main/.licenserc.yaml).

Our choice of the [weak-copyleft](https://www.tldrlegal.com/license/mozilla-public-license-2-0-mpl-2) MPL license reflects a strategic balance:

1. **Commitment to open-source freedom**:
We believe that OS kernels are a communal asset that should benefit humanity.
The MPL ensures that any alterations to MPL-covered files remain open source,
aligning with our vision.
Additionally, we do not require contributors
to sign a Contributor License Agreement (CLA),
[preserving their rights and preventing the possibility of their contributions being made closed source](https://drewdevault.com/2018/10/05/Dont-sign-a-CLA.html).

2. **Accommodating proprietary modules**:
Recognizing the evolving landscape
where large corporations also contribute significantly to open-source,
we accommodate the business need for proprietary kernel modules.
Unlike GPL,
the MPL permits the linking of MPL-covered files with proprietary code.

In conclusion, we believe that
MPL is the best choice
to foster a vibrant, robust, and inclusive open-source community around OmegaOS W3.x.
