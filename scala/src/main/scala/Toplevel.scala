import spinal.core._
import spinal.lib._

// --- Annahme: AesIterative ist deine Spinal-Komponente mit folgenden Ports:
// aes.io.start   : in Bool
// aes.io.decrypt : in Bool
// aes.io.key     : in Bits(128 bits)
// aes.io.dataIn  : in Bits(128 bits)
// aes.io.dataOut : out Bits(128 bits)
// aes.io.busy    : out Bool
// aes.io.done    : out Bool
// Falls die Namen abweichen, passe die Verbindungen weiter unten an.

class AesTop_WithAesIterative extends Component {
  val io = new Bundle {
    val start        = in Bool()      // Master pulst 1 cycle
    val decrypt      = in Bool()
    val key_bit      = in Bool()      // single-bit key input
    val dataIn_bit   = in Bool()      // single-bit data input
    val dataOut_bit  = out Bool()     // reduced output (parity)
    val busy         = out Bool()
    val done         = out Bool()
    val clk          = in Bool()
    val reset        = in Bool()
  }

  // externe ClockDomain
  val cd = ClockDomain(io.clk, io.reset)
  val area = new ClockingArea(cd) {
    // Instanziere deinen AES Core (ersetze falls nötig)
    val aes = new AesIterative

    // --- Sample die 1-bit Inputs in Regs, damit Setup vor Start garantiert ist ---
    val sampledKeyBit  = RegNext(io.key_bit, False)
    val sampledDataBit = RegNext(io.dataIn_bit, False)

    // --- Expand 1-bit auf 128 bits (alle Bits identisch) ---
    val keyExpanded  = Vec.fill(128)(sampledKeyBit.asBits).asBits
    val dataExpanded = Vec.fill(128)(sampledDataBit.asBits).asBits

    // --- Verbinde die Inputs mit dem AES-Core ---
    aes.io.decrypt := io.decrypt
    aes.io.key     := keyExpanded
    aes.io.dataIn  := dataExpanded

    // --- FSM zur Steuerung des Start-Pulses und Warten auf Done ---
    val state = RegInit(U(0, 2 bits)) // korrekt: U(0, 2 bits)
    val IDLE  = U(0, 2 bits)
    val START = U(1, 2 bits)
    val WAIT  = U(2, 2 bits)
    val DONE  = U(3, 2 bits)

    // Default: kein Start-Puls
    aes.io.start := False

    // Default-Ausgänge
    io.busy := False
    io.done := False
    io.dataOut_bit := False

    switch(state) {
      is(IDLE) {
        // Warte auf Start-Puls vom Master. Wir sampleten die Bits bereits.
        when(io.start) {
          // pulse start für genau 1 Cycle
          aes.io.start := True
          io.busy := True
          state := START
        }
      }

      is(START) {
        // Start-Puls wurde in der vorherigen Cycle gesetzt (aes.io.start ist nur in IDLE gesetzt)
        // Jetzt gehen wir in WAIT, um auf aes.io.done zu warten
        io.busy := True
        state := WAIT
      }

      is(WAIT) {
        io.busy := True
        // Warte auf das done-Signal des AES-Cores
        when(aes.io.done) {
          state := DONE
        }
      }

      is(DONE) {
        // Reduziere 128-bit Output auf 1 Bit (Parity / XOR-Reduction)
        io.dataOut_bit := aes.io.dataOut.xorR
        io.done := True
        io.busy := False
        // eine Cycle done high, dann zurück zu IDLE
        state := IDLE
      }
    }

    // Optional: wenn du io.busy/io.done direkt vom Core durchreichen willst,
    // kannst du das statt der FSM-Flags tun:
    // io.busy := aes.io.busy
    // io.done := aes.io.done
  } // end ClockingArea
}

// Verilog-Emitter
object AesTop_WithAesIterativeVerilog {
  def main(args: Array[String]): Unit = {
    SpinalVerilog(new AesTop_WithAesIterative)
  }
}
