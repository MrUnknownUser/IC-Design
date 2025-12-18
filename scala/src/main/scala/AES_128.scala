import spinal.core._
import spinal.lib._

class AesIterative extends Component {
  val io = new Bundle {
    val start   = in Bool()
    val key     = in Bits(128 bits)
    val dataIn  = in Bits(128 bits)
    val dataOut = out Bits(128 bits)
    val busy    = out Bool()
    val done    = out Bool()
  }

  // S-Box
  val sboxTable = Array(
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
    0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
    0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
    0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
    0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
    0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
    0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
    0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
    0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
    0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
    0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
    0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
    0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
  ).map(_.toInt)

  val sboxRom = Vec(UInt(8 bits), 256)
  for(i <- 0 until 256) sboxRom(i) := U(sboxTable(i), 8 bits)
  def sbox(b: UInt): UInt = sboxRom(b)

  val rcon = Vec(
    U(0x01, 8 bits), U(0x02, 8 bits), U(0x04, 8 bits), U(0x08, 8 bits),
    U(0x10, 8 bits), U(0x20, 8 bits), U(0x40, 8 bits), U(0x80, 8 bits),
    U(0x1B, 8 bits), U(0x36, 8 bits)
  )

  // Registers / state
  val stateReg    = Reg(Bits(128 bits)) init(B(0, 128 bits))
  val roundKeyReg = Reg(Vec(UInt(32 bits), 4))
  for(i <- 0 until 4) roundKeyReg(i) init(0)
  val roundCount  = Reg(UInt(4 bits)) init(U(0))
  val running     = Reg(Bool) init(False)
  val rconCounter = Reg(UInt(4 bits)) init(U(0))

  io.busy    := running
  io.done    := False
  io.dataOut := stateReg

  // Helpers: mapping (column-major)
  def bitsToMatrix(b: Bits): Vec[UInt] = {
    val v = Vec(UInt(8 bits), 16)
    for(i <- 0 until 16){
      val hi = 127 - i*8
      val lo = 120 - i*8
      v(i) := b(hi downto lo).asUInt
    }
    v
  }
  def matrixToBits(v: Vec[UInt]): Bits = {
    (v(0) ## v(1) ## v(2) ## v(3) ##
     v(4) ## v(5) ## v(6) ## v(7) ##
     v(8) ## v(9) ## v(10) ## v(11) ##
     v(12) ## v(13) ## v(14) ## v(15)).asBits
  }
  def idx(col: Int, row: Int) = col*4 + row

  def xtime(x: UInt): UInt = {
    val shifted = (x << 1)(7 downto 0)
    val msb     = x.msb
    msb ? (shifted ^ U(0x1b, 8 bits)) | shifted
  }
  def mul2(x: UInt) = xtime(x)
  def mul3(x: UInt) = xtime(x) ^ x

  def mixColumn(b0: UInt, b1: UInt, b2: UInt, b3: UInt): Vec[UInt] = {
    val y = Vec(UInt(8 bits), 4)
    y(0) := (mul2(b0) ^ mul3(b1) ^ b2 ^ b3)
    y(1) := (b0 ^ mul2(b1) ^ mul3(b2) ^ b3)
    y(2) := (b0 ^ b1 ^ mul2(b2) ^ mul3(b3))
    y(3) := (mul3(b0) ^ b1 ^ b2 ^ mul2(b3))
    y
  }

  def keyWordsToMatrix(keyWords: Vec[UInt]): Vec[UInt] = {
    def wordTo4(x: UInt): Vec[UInt] = {
      val v = Vec(UInt(8 bits), 4)
      v(0) := x(31 downto 24)
      v(1) := x(23 downto 16)
      v(2) := x(15 downto 8)
      v(3) := x(7 downto 0)
      v
    }
    val w0 = wordTo4(keyWords(0))
    val w1 = wordTo4(keyWords(1))
    val w2 = wordTo4(keyWords(2))
    val w3 = wordTo4(keyWords(3))
    val rk = Vec(UInt(8 bits), 16)
    for(i <- 0 until 4) {
      rk(i) := w0(i)
      rk(i+4) := w1(i)
      rk(i+8) := w2(i)
      rk(i+12) := w3(i)
    }
    rk
  }

  def bitsToWords(b: Bits): Vec[UInt] = {
    val v = Vec(UInt(32 bits), 4)
    for(i <- 0 until 4){
      val hi = 127 - i*32
      val lo = 96  - i*32
      v(i) := b(hi downto lo).asUInt
    }
    v
  }

  def computeRoundKey(currKey: Vec[UInt], rconVal: UInt): Vec[UInt] = {
    val w3 = currKey(3)
    val rot = (w3(23 downto 0) ## w3(31 downto 24)).asUInt
    val s0 = sbox(rot(31 downto 24))
    val s1 = sbox(rot(23 downto 16))
    val s2 = sbox(rot(15 downto 8 ))
    val s3 = sbox(rot(7  downto 0 ))
    val subw = (s0 ## s1 ## s2 ## s3).asUInt
    val rconWord = (rconVal ## U(0, 24 bits)).asUInt
    val tempWord = (subw ^ rconWord)
    val w0p = (currKey(0) ^ tempWord)
    val w1p = (currKey(1) ^ w0p)
    val w2p = (currKey(2) ^ w1p)
    val w3p = (currKey(3) ^ w2p)
    Vec(w0p, w1p, w2p, w3p)
  }

  // combi wires with Default (always defined)
  val newStateComb = Bits(128 bits)
  newStateComb := B(0, 128 bits)

  val rkBitsUsedComb = Bits(128 bits)
  rkBitsUsedComb := B(0, 128 bits)


  // Control
  when(io.start && !running) {
    running := True

    val initWords  = bitsToWords(io.key)
    val initKeyMat = keyWordsToMatrix(initWords)
    val initStateMat = bitsToMatrix(io.dataIn)

    val tmpAfter0 = Vec(UInt(8 bits), 16)
    for(i <- 0 until 16) tmpAfter0(i) := (initStateMat(i) ^ initKeyMat(i))
    stateReg    := matrixToBits(tmpAfter0)
    roundKeyReg := initWords
    roundCount  := U(0)
    rconCounter := U(0)

  }.elsewhen(running) {
    val m = bitsToMatrix(stateReg)

    // SubBytes
    val sub = Vec(UInt(8 bits), 16)
    for(i <- 0 until 16) sub(i) := sbox(m(i))

    // ShiftRows
    val shifted = Vec(UInt(8 bits), 16)
    shifted(idx(0,0)) := sub(idx(0,0))
    shifted(idx(1,0)) := sub(idx(1,0))
    shifted(idx(2,0)) := sub(idx(2,0))
    shifted(idx(3,0)) := sub(idx(3,0))
    shifted(idx(0,1)) := sub(idx(1,1))
    shifted(idx(1,1)) := sub(idx(2,1))
    shifted(idx(2,1)) := sub(idx(3,1))
    shifted(idx(3,1)) := sub(idx(0,1))
    shifted(idx(0,2)) := sub(idx(2,2))
    shifted(idx(1,2)) := sub(idx(3,2))
    shifted(idx(2,2)) := sub(idx(0,2))
    shifted(idx(3,2)) := sub(idx(1,2))
    shifted(idx(0,3)) := sub(idx(3,3))
    shifted(idx(1,3)) := sub(idx(0,3))
    shifted(idx(2,3)) := sub(idx(1,3))
    shifted(idx(3,3)) := sub(idx(2,3))

    // MixColumns (pass-through here; keep real mixColumn if needed)
    val mixed = Vec(UInt(8 bits), 16)
    when(roundCount === U(9)) {
      // Finale Round: no MixColumns, pass-through
      for(i <- 0 until 16) mixed(i) := shifted(i)
    } otherwise {
      // Normal round: use MixColumns
      def mixCol(c: Int) = {
        val y = mixColumn(
          shifted(idx(c,0)), shifted(idx(c,1)),
          shifted(idx(c,2)), shifted(idx(c,3))
        )
        mixed(idx(c,0)) := y(0)
        mixed(idx(c,1)) := y(1)
        mixed(idx(c,2)) := y(2)
        mixed(idx(c,3)) := y(3)
      }
      mixCol(0); mixCol(1); mixCol(2); mixCol(3)
    }

    val newState = matrixToBits(mixed)
    newStateComb := newState


    // Key schedule
    val nextRoundKey = computeRoundKey(roundKeyReg, rcon(rconCounter))
    val rkBitsUsed = matrixToBits(keyWordsToMatrix(nextRoundKey)) // key used this cycle
    rkBitsUsedComb := rkBitsUsed

    // compute and apply AddRoundKey
    val stateComb = newState ^ rkBitsUsed
    stateReg := stateComb

    // update key for next round
    roundKeyReg := nextRoundKey

    // counters
    when(roundCount === U(10)) {
      running := False
      io.done := True
      io.dataOut := stateReg
    } otherwise {
      roundCount := roundCount + 1
      when(rconCounter < U(9)) { rconCounter := rconCounter + 1 }
    }
  }
}
