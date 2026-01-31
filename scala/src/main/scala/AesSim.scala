import spinal.core._
import spinal.sim._
import spinal.core.sim._

object AesSim {
  def main(args: Array[String]): Unit = {
    SimConfig.withFstWave.doSim(new AesIterative) { dut =>
      val key       = BigInt("2b7e151628aed2a6abf7158809cf4f3c", 16)
      val plaintext = BigInt("3243f6a8885a308d313198a2e0370734", 16)
      val expected  = BigInt("3925841d02dc09fbdc118597196a0b32", 16)

      // initial signals
      dut.io.start #= false
      dut.io.decrypt#= false
      dut.io.key #= key
      dut.io.dataIn #= plaintext

      dut.clockDomain.forkStimulus(period = 10)
      dut.clockDomain.waitSampling()
      
      // start encrypt
      dut.io.start #= true
      dut.clockDomain.waitSampling()
      dut.io.start #= false

      // wait until done or timeout
      var cycles = 0
      while(!dut.io.done.toBoolean && cycles < 500) {
        dut.clockDomain.waitSampling()
        cycles += 1
      }

      val cipherOut = dut.io.dataOut.toBigInt
      println(s"Encryption fertig nach $cycles cycles")
      println("Key      = " + key.toString(16))
      println("Plain    = " + plaintext.toString(16))
      println("Cipher   = " + cipherOut.toString(16))
      println("Expected = " + expected.toString(16))
      if(cipherOut == expected) println("Encrypt: OK (matches expected)") else println("Encrypt: MISMATCH")

      // optional pause
      dut.clockDomain.waitSampling(2)
      
      // start decrypt
      cycles = 0
      dut.io.decrypt #= true
      dut.io.key #= key
      dut.io.dataIn #= expected

      // pulse start for decrypt
      dut.io.start #= true
      dut.clockDomain.waitSampling()
      dut.io.start #= false

      // wait until done oder timeout
      cycles = 0
      while(!dut.io.done.toBoolean && cycles < 500) {
        dut.clockDomain.waitSampling()
        cycles += 1
      }

      val plainOut = dut.io.dataOut.toBigInt
      println(s"Decryption fertig nach $cycles cycles")
      println("Recovered Plain = " + plainOut.toString(16))
      if(plainOut == plaintext) println("Decrypt: OK (recovered original plaintext)") else println("Decrypt: MISMATCH")

      // End simulation
      dut.clockDomain.waitSampling(5)
    }
  }
}
