"""
Embedded Python Blocks:

Each time this file is saved, GRC will instantiate the first class it finds
to get ports and parameters of your block. The arguments to __init__  will
be the parameters. All of them are required to have default values!
"""
import matlab.engine
import numpy as np
from gnuradio import gr


#   注意： 该项目的 PSS_SSS_detect 中开头加入取实部操作！
# 故，与其他项目的PSS_SSS_detect 不同！


class blk(gr.sync_block):  # other base classes are basic_block, decim_block, interp_block
    """Embedded Python Block example - a simple multiply const"""

    def __init__(self, number_points=153600):  # only default arguments here
        """arguments to this function show up as parameters in GRC"""
        gr.sync_block.__init__(
            self,
            name='Embedded Python Block',  # will show up in GRC
            in_sig=[np.complex64],
            out_sig=[np.complex64]
        )
        # if an attribute with the same name as a parameter is found,
        # a callback is registered (properties work, too).
        self.number_points = number_points
        self.eng = matlab.engine.start_matlab()
        self.buff = np.array([0. + 0j])
        self.buff = np.delete(self.buff, 0)

    def work(self, input_items, output_items):
        """example: multiply with constant"""
        # 缓存区只有4096，通过判断len(input_items[0]与4096的关系来判断是否为最后一次读完，除非进入的)
        # print(output_items[0])
        # print(type(input_items[0]))
        self.buff = np.append(self.buff, input_items[0])
        # A = self.eng.test2(input_items[0])
        # print(A)
        output_items[0][:] = input_items[0]
        if len(self.buff) == self.number_points * 2:
            self.buff = self.buff[self.number_points:self.number_points*2+1]
            NID2, NID1, CeiID = self.eng.PSS_SSS_detect(self.buff, nargout=3)
            print("NID2:" + str(NID2))
            print("NID1:" + str(NID1))
            print("CeilID:" + str(CeiID))
        return len(output_items[0])
