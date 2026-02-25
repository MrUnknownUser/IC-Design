import spinal.core._

object GenerateVerilog {
  def main(args: Array[String]): Unit = {
    // Ersetze AesTop_WithAesIterative durch deinen Top‑Klassenname
    SpinalVerilog(new AesTop_WithAesIterative)
  }
}
