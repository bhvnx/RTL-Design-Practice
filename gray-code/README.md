# Gray code generator

Converts an N-bit binary value to its Gray code equivalent using the standard
formula `gray = binary ^ (binary >> 1)`.

## Design

```
binary[WIDTH-1:0]  →  gray[WIDTH-1:0]

gray[i] = binary[i+1] ^ binary[i]   for i = 0 .. WIDTH-2
gray[WIDTH-1] = binary[WIDTH-1]      (wire, no gate)
```

The MSB passes through unchanged. Every other output bit is an independent
2-input XOR of two adjacent binary bits.

---

## Synthesis results (Yosys 0.58, generic target)

### Fixed (8-bit) vs parameterized at WIDTH=8

| Design | Cells | Cell types | Logic depth |
|---|---|---|---|
| `gray_code_generator.sv` (fixed 8-bit) | 7 | 7× `$_XOR_` | **1** |
| `gray_code_param.sv` WIDTH=8 | 7 | 7× `$_XOR_` | **1** |

Identical. After elaboration at WIDTH=8, both produce the same Boolean equations
and Yosys generates the same netlist. Parameterization has zero synthesis
overhead.

### Scaling with WIDTH (parameterized)

| WIDTH | XOR cells | Logic depth | Critical path |
|---|---|---|---|
| 4 | 3 | **1** | `binary[3] → gray[2]` |
| 8 | 7 | **1** | `binary[7] → gray[6]` |
| 16 | 15 | **1** | `binary[15] → gray[14]` |

Cell count scales as `WIDTH - 1` (the MSB is a free wire).
Logic depth is always **1 gate level**, independent of WIDTH.

### Observations

**Logic depth is constant regardless of width.**
All XOR gates are independent — `gray[i] = binary[i+1] ^ binary[i]` for each
`i` with no gate depending on another gate's output. The circuit is fully
parallel. Doubling the width doubles gate count but the critical path stays at
one XOR gate. This contrasts directly with the priority encoder, where adding
an input lengthened the critical path.

**Cell count is `WIDTH - 1`, not `WIDTH`.**
The MSB requires no gate: `gray[WIDTH-1] = binary[WIDTH-1]` is a direct
connection. Yosys's WREDUCE/OPT passes recognize this and emit no cell for it.

**The formula naturally exposes maximum parallelism.**
`binary ^ (binary >> 1)` is a bitwise operation with no carry or dependency
chain between bit positions. Synthesis has nothing to optimize beyond mapping
each XOR to a single cell — there is no room for ABC restructuring to change
the result.

---

## Testbench coverage

- **Exhaustive value check** — all 256 inputs verified against the reference
  formula `binary ^ (binary >> 1)`.
- **Adjacency check** — DUT outputs for every consecutive pair of inputs
  (0→1, 1→2, … 254→255) verified to differ by exactly one bit, confirming the
  defining property of Gray code.

---

## Bugs found

- **`output reg` driven by `assign`.** The original declared `output reg gray`
  while driving it with a continuous assignment, creating a multi-driver
  conflict. Fixed to `output wire`.
