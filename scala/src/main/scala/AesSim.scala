import spinal.core._
import spinal.sim._
import spinal.core.sim._

object AesSim {
  def main(args: Array[String]): Unit = {
    SimConfig.withFstWave.doSim(new AesIterative) { dut =>
      val key       = BigInt("2b7e151628aed2a6abf7158809cf4f3c", 16)
      val plaintext = BigInt("3243f6a8885a308d313198a2e0370734", 16)
      val expected  = BigInt("3925841d02dc09fbdc118597196a0b32", 16)

      dut.io.start  #= false
      dut.io.key    #= key
      dut.io.dataIn #= plaintext

      dut.clockDomain.forkStimulus(period = 10)
      dut.clockDomain.waitSampling()

      // pulse start
      dut.io.start #= true
      dut.clockDomain.waitSampling()
      dut.io.start #= false
      dut.clockDomain.waitSampling()

      var cycles = 0
      while(!dut.io.done.toBoolean && cycles < 200) {
        dut.clockDomain.waitSampling()

        cycles += 1
      }

      val out = dut.io.dataOut.toBigInt
      println(s"Sim fertig nach $cycles cycles")
      println("Key      = " + key.toString(16))
      println("Plain    = " + plaintext.toString(16))
      println("Cipher   = " + out.toString(16))
      println("Expected = " + expected.toString(16))
      if(out == expected) println("Result: OK (matches expected)") else println("Result: MISMATCH")
    }
  }
}
