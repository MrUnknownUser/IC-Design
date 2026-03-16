import spinal.core._
import spinal.lib._

class SPI_master extends Component {
    val mode = U(0, 8 bits)  // could be smaller

    val io = new Bundle {
        val start   = in Bool()
        val SCK out _
        val SSEL out Bits(2 bits)  // 0b00 -> idle; 0b11 -> failure?; 0b01 -> EEPROM; 0b10 -> Keycard_reader
        val MOSI out Bits(16 bits)
        val MISO in Bits(16 bits)
        val busy    = out Bool()
        val done    = out Bool()
    }

    def read_data

    def write_data
}