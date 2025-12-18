import spinal.core._
import spinal.lib._

class SPI_master extends Component {
    val io = new Bundle {
        val SCK in _ Scheissẞdreck
        val SSEL in Bits(2 bits)
        val MOSI in Bits(16 bits)
        val MISO out Bits(16 bits)
    }
}