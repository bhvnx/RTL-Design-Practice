# Adders

Two parameterizable adder implementations with the same port interface,
compared by cell count and critical-path depth (synthesized with Yosys/ABC,
generic gate library, WIDTH=2).

```
module adder #(parameter WIDTH = 2)(
    input  wire [WIDTH-1:0] a, b,
    input  wire             cin,
    output wire [WIDTH:0]   out     // WIDTH+1 bits — captures carry-out
);
```

---

## Implementations

### `adder_df.sv` — Dataflow (Ripple-Carry)

```sv
assign out = a + b + cin;
```

Relies on the synthesiser to infer carry logic. The `+` operator produces a
ripple-carry chain: carry into bit `i` cannot be known until bit `i-1`
completes, so each stage waits on the one below it.

### `adder_cla.sv` — Carry Look-Ahead (CLA)

Explicitly computes bit-level **generate** `G[i] = a[i] & b[i]` and
**propagate** `P[i] = a[i] ^ b[i]`, then derives every carry in parallel as a
single-level sum-of-products:

```
carry[i+1] = G[i]
           | pp[i][i]   · G[i-1]
           | pp[i][i-1] · G[i-2]
           | ...
           | pp[i][0]   · cin
```

where `pp[i][j] = P[i] & P[i-1] & … & P[j]`.  No carry waits on another
carry; all are resolved in one AND-OR stage after the generate/propagate
precompute.

---

## Synthesis Results (WIDTH = 2)

| Metric                  | Dataflow (ripple) | CLA        |
|-------------------------|:-----------------:|:----------:|
| Total cells             | **10**            | **13**     |
| `$_AND_` / `$_ANDNOT_`  | 1 + 2 = 3         | 1 + 3 = 4  |
| `$_OR_`                 | 1                 | 3          |
| `$_XOR_` / `$_XNOR_`   | 1 + 3 = 4         | 1 + 3 = 4  |
| `$_NAND_` / `$_NOR_`   | 1 + 1 = 2         | 1 + 1 = 2  |
| **Critical path (gates)**| **5**            | **4**      |
| Critical endpoint       | `out[2]` (carry)  | `out[2]`   |
| Critical start point    | `b[0]`            | `b[1]`     |

Stat files: [`synth/stat_adder_df.txt`](synth/stat_adder_df.txt) ·
[`synth/stat_adder_cla.txt`](synth/stat_adder_cla.txt)

---

## Analysis

### Area vs. Speed trade-off

The CLA uses **3 more cells** (13 vs 10, +30%) but reduces the longest path
by **1 gate level** (4 vs 5, −20%).  This is the classic CLA trade-off: more
logic to pre-compute propagate products, in exchange for a shallower carry
tree.

### Why the gap is small at WIDTH = 2

A 2-bit adder is too narrow for CLA to show its full advantage.  The critical
path of a ripple-carry adder grows as **O(N)** while CLA grows as
**O(log₂ N)**:

| WIDTH | Ripple path (theory) | CLA path (theory) |
|------:|:--------------------:|:-----------------:|
| 2     | ~5 gates             | ~4 gates          |
| 4     | ~9 gates             | ~5 gates          |
| 8     | ~17 gates            | ~6 gates          |
| 16    | ~33 gates            | ~7 gates          |

The area overhead of CLA also grows (more propagate-product terms per carry),
but the relative area cost shrinks at large widths because a ripple adder
needs proportionally more full-adder cells.

### ABC optimisation note

Both netlists target a generic gate library (no liberty file), so ABC uses
unit-delay optimisation.  With a real standard-cell library the absolute
numbers change, but the relative ordering — CLA faster, CLA larger — holds.

### Critical path endpoint

Both designs have `out[2]` (the carry-out bit) as the slowest output, which
is expected: the carry-out of a WIDTH-bit adder is the last signal resolved in
both topologies.

---

## Running simulation and synthesis

```bash
# Simulate (from adders/)
iverilog -g2012 -o build/sim_df.out  rtl/adder_df.sv  tb/tb_adder.sv && vvp build/sim_df.out
iverilog -g2012 -o build/sim_cla.out rtl/adder_cla.sv tb/tb_adder.sv && vvp build/sim_cla.out

# Synthesise (re-run)
yowasp-yosys -p "read_verilog -sv rtl/adder_df.sv;  synth -top adder; tee -o synth/stat_adder_df.txt  stat; tee -a synth/stat_adder_df.txt  ltp -noff"
yowasp-yosys -p "read_verilog -sv rtl/adder_cla.sv; synth -top adder; tee -o synth/stat_adder_cla.txt stat; tee -a synth/stat_adder_cla.txt ltp -noff"
```
