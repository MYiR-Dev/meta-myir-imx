# OV13855 ISP tuning log

## 2026-08-17: 1280x720 NV12 60 fps Weston preview

Baseline IQ SHA-256:

`f3a97fb878f4169871ee9334a6630ed8e1b354559e25b60ff0c0d6b9a9d3c35a`

Observed baseline:

- Sensor input: 2112x1568 at 60 fps.
- ISP output: 1280x720 NV12 at 60 fps.
- Stable sensor controls: exposure 964 lines, analogue gain 1984 (maximum).
- Stable processed-frame luma: mean 69.57, median 66, p90 85.
- The image was dark and showed low-level red/blue temporal speckle.
- Five consecutive stable frames had no persistent strong red outlier, so the
  symptom was treated as high-gain chroma noise rather than fixed bad pixels.

Experiment EXP-60-B10-DN2:

- CPROC brightness: 0 -> +10.
- FILTER denoise: 0 -> 2.
- FILTER sharpen remains 1.
- AE set point remains 70 because the sensor is already at maximum analogue
  gain at 60 fps; raising the target would not add physical exposure.
- DPCC, DPF, fixed white balance, BLS and LSC were not changed.

Measured result:

- Processed-frame luma mean: 69.57 -> 81.53.
- Median luma: 66 -> 79.
- Uniform-region horizontal luma difference mean: 0.471 -> 0.360 (-23.6%).
- Uniform-region U difference mean: 0.338 -> 0.283 (-16.3%).
- Uniform-region V difference mean: 0.352 -> 0.295 (-16.2%).
- Preview remained at 60 fps under Weston/Wayland.

Rollback:

- Restore CPROC config to `AgAAAAIAAAACAAAAAACAPwAAAAAAAIA/AAAAAA==`
  (brightness 0).
- Restore `<denoise>0</denoise>`.

## 2026-08-17: resolution-specific IQ profiles

Multiple IQ XML files are supported and are required here because ISP
calibration metadata and processing geometry must match the selected active
input resolution.

Installed profiles:

- `OV13855_13M_10_2112x1568_linear.xml`: mode 0, native binned
  2112x1568 RAW10 at 60fps;
- `OV13855_13M_10_4096x3072_linear.xml`: mode 1, centered ISP crop from the
  native 4224x3136 RAW10 sensor stream at 15fps;
- `OV13855_13M_10_4224x3136_linear.xml`: packaged diagnostic profile for the
  complete sensor geometry, not selected on i.MX8MP because its ISP active
  window is limited to 4096x3072.

Matching DWE bypass JSON files are installed for all three resolutions.  The
runtime mapping is recorded in `Sensor0_Entry.cfg` by `run_ov13855.sh`:

```ini
[mode.0]
xml = "OV13855_13M_10_2112x1568_linear.xml"
dwe = "dewarp_config/sensor_dwe_ov13855_2112x1568_bypass.json"

[mode.1]
xml = "OV13855_13M_10_4096x3072_linear.xml"
dwe = "dewarp_config/sensor_dwe_ov13855_4096x3072_bypass.json"
```

Validated rates and image results:

- mode 0: 59.86fps measured, recognizable stable image;
- mode 1: 14.97fps measured, recognizable stable image;
- no vertical bars, diagonal transport bands, repeated blocks, or black
  borders in either accepted image.

Package-split SHA-256 values:

```text
2112 XML  9ec40965ff10c99f7c9dfb7e64009e51ef7e83da78f7af62159e41efb6a86276
4096 XML  6b9b8a81e04239956005b2df7284ad84699e337cd72a85b658e3c5f271c87a8c
4224 XML  c4f0df0aa571ae3646ff5c232194bc4a4b80face1717771b44b3b1d907327dd1
2112 JSON 72c32198521acbba8ac3d83d7e20a4ef8b5226e830b6f99f68ae919412ee9e09
4096 JSON a88881f8f6acbdf91ecc5e12147631d65728aa23676f247e5181739865d3c326
4224 JSON 1f1df7f76b357d681ab5de665476786b57684b4831d9e99fdbda50cafbcf9f33
```

Select a mode with:

```sh
OV13855_MODE=0 /opt/imx8-isp/bin/run_ov13855.sh
OV13855_MODE=1 /opt/imx8-isp/bin/run_ov13855.sh
```

Mode 0 remains the default and is the final Weston preview state.

## 2026-08-17: rejected mode 0 brightness +20 experiment

The live 2112x1568 RAW10 60fps mode was already at its physical exposure
limit in the current scene:

- exposure registers: `0x3500..0x3502 = 00 3c 40`, 964 lines/about 10ms;
- analogue gain: `0x3508..0x3509 = 07 c0`, maximum;
- VTS: `0x380e..0x380f = 06 48`, 1608 lines;
- measured output rate remained 59.86fps.

Increasing the AEC set point cannot add physical exposure in this state.
Therefore only the mode 0 CPROC brightness was changed from +10 to +20.  AEC,
gamma, white balance, CCM, DPF, denoise 2 and sharpen 1 were left unchanged.

Stable 1280x720 NV12 comparison:

```text
                 Y min   Y mean   Y median   Y max   Y stddev   Y >= 235
brightness +10      61     78.20         75     160      11.32          0
brightness +20      72     87.69         83     153      10.76          0
```

Although +20 raised dark-scene visibility without highlight clipping or a
frame-rate change, live HDMI inspection showed a layered gray haze.  The
fixed offset raised the black floor from Y=61 to Y=72 instead of adding real
exposure, so +20 was rejected and fully rolled back to +10.  +30 was not
tested.  The board rollback copy is:

`/root/ov13855-iq-backup-20260817-dark/OV13855_13M_10_2112x1568_linear.b10.xml`

Rejected +20 candidate IQ SHA-256:

`5a4b57a2e12227dacdb86cf94d78b0e0f64f0efe17ff8eb88144792452d1ed30`

Formal `bitbake isp-imx` validation used `MACHINE=myd-js8mpq` and
`DISTRO=fsl-imx-xwayland`: 1,860 tasks were attempted and all succeeded.  The
package-split XML was byte-identical to the tested +20 candidate.  This build
is superseded by the subsequent +10 rollback build.

Rollback validation forced `isp-imx:do_install` and then resumed the complete
`bitbake isp-imx` target.  Both commands succeeded; the final source,
package-split and deployed board XML are byte-identical with SHA-256
`9ec40965ff10c99f7c9dfb7e64009e51ef7e83da78f7af62159e41efb6a86276`.

## 2026-08-17: accepted 60 fps color candidate and Yocto source freeze

The final live Weston tuning retained the validated mode 0 transport and made
only ISP color/tonal changes.  The accepted runtime state is:

- sensor input: 2112x1568 linear RAW10 at 60fps;
- ISP/preview output: 1280x720 NV12 at 60fps;
- WDR v1/v3 disabled;
- CPROC contrast 1.15, brightness +3, saturation 1.30, hue 0;
- midtone-v1 gamma curve;
- filter denoise 2 and sharpen 1;
- fixed WB gains: red 1.30, green 1.00/1.00, blue 1.18;
- CCM:
  `[1.509377,-0.551196,0.041819,-0.181204,1.343728,-0.162524,`
  `-0.402954,-0.324219,1.727173]`.

The preceding candidate used blue gain 1.15 and had SHA-256
`0cb6c8fc96320e2be638bb911614d7db457dfea929424c9052017f02ab3d650b`.
Live HDMI inspection found a small remaining yellow cast.  Blue gain was the
only changed variable and was raised from 1.15 to 1.18.  The user confirmed
the resulting preview was acceptable; red gain, CCM, gamma, CPROC, exposure,
resolution and frame rate were unchanged.

The accepted 2112x1568 IQ SHA-256 is:

`1e9b647c60a6e3e2661b7a4627ae26a72590644daaced7bef41ca979824f9bed`

The Yocto recipe already lists this XML in `SRC_URI`, installs it over the
generated OV13855 calibration payload during `do_configure`, and packages it
through the normal `isp-imx` install.  The recipe source and the deployed board
file were byte-identical at acceptance time.  No new BitBake build was run for
this final blue-gain adjustment; package-split and image validation remain the
next integration step.

Final post-settle capture evidence:

- NV12: `ov13855-final-b118-frame29.nv12`, SHA-256
  `00ec0d1cc277c1cbf27a75893bbbb1c34d636db7c4777762f9c66592344b5c56`;
- PNG: `ov13855-final-b118-frame29.png`, SHA-256
  `094ad1e22f325f3ecaeb0907a966c6992608003d331af446af03a7c97737cf34`;
- image size 1280x720, RGB mean 80.87/72.70/75.35, grayscale mean 75.43
  and standard deviation 21.10.

The image contains the orange barrier, monitor, cables and lamp with
continuous geometry.  No vertical bars, diagonal transport bands, repeated
blocks, or black border are present.  Weston preview was restored afterward
at 1280x720 NV12 and reported 60.000fps.
