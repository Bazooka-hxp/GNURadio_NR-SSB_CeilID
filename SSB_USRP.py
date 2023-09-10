#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: SSB_USRP
# Author: rtt1
# GNU Radio version: v3.8.5.0-6-g57bd109d

from distutils.version import StrictVersion

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print("Warning: failed to XInitThreads()")

from PyQt5 import Qt
from gnuradio import qtgui
from gnuradio.filter import firdes
import sip
from gnuradio import blocks
from gnuradio import filter
from gnuradio import gr
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import uhd
import time
from gnuradio.qtgui import Range, RangeWidget
import epy_block_0

from gnuradio import qtgui
import matlab.engine
import numpy as np

class SSB_USRP(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "SSB_USRP")
        Qt.QWidget.__init__(self)
        self.setWindowTitle("SSB_USRP")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "SSB_USRP")

        self.sin_wave = eng.python_SSB_SignalCreate()
        self.sin_wave = np.array(self.sin_wave)
        self.sin_real = np.real(self.sin_wave[0])
        self.sin_imag = np.imag(self.sin_wave[0])
        self.sin_real = tuple(self.sin_real)
        self.sin_imag = tuple(self.sin_imag)

        try:
            if StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
                self.restoreGeometry(self.settings.value("geometry").toByteArray())
            else:
                self.restoreGeometry(self.settings.value("geometry"))
        except:
            pass

        ##################################################
        # Variables
        ##################################################
        self.gain_lowpass2 = gain_lowpass2 = 5
        self.gain_lowpass1 = gain_lowpass1 = 5
        self.volume = volume = 1
        self.samp_rate = samp_rate = 100000
        self.gain_transmit = gain_transmit = 10
        self.gain_receive = gain_receive = 10
        self.Lowpass2 = Lowpass2 = firdes.low_pass(gain_lowpass2, 1e6, 20e3,1e3, firdes.WIN_HAMMING, 6.76)
        self.Lowpass = Lowpass = firdes.low_pass(gain_lowpass1, 1e6, 30e3,1e3, firdes.WIN_HAMMING, 6.76)

        ##################################################
        # Blocks
        ##################################################
        self._volume_range = Range(0, 10, 0.1, 1, 200)
        self._volume_win = RangeWidget(self._volume_range, self.set_volume, 'Audio Gain', "counter_slider", float)
        self.top_layout.addWidget(self._volume_win)
        self._gain_transmit_range = Range(0, 31.5, 1, 10, 200)
        self._gain_transmit_win = RangeWidget(self._gain_transmit_range, self.set_gain_transmit, 'gain_transmit', "counter_slider", float)
        self.top_layout.addWidget(self._gain_transmit_win)
        self._gain_receive_range = Range(0, 31.5, 1, 10, 200)
        self._gain_receive_win = RangeWidget(self._gain_receive_range, self.set_gain_receive, 'gain_receive', "counter_slider", float)
        self.top_layout.addWidget(self._gain_receive_win)
        self.uhd_usrp_source_0 = uhd.usrp_source(
            ",".join(("serial=3297D84", "")),
            uhd.stream_args(
                cpu_format="fc32",
                args='',
                channels=list(range(0,1)),
            ),
        )
        self.uhd_usrp_source_0.set_center_freq(4.9e9, 0)
        self.uhd_usrp_source_0.set_gain(gain_receive, 0)
        self.uhd_usrp_source_0.set_antenna('RX2', 0)
        self.uhd_usrp_source_0.set_samp_rate(1e6)
        # No synchronization enforced.
        self.uhd_usrp_sink_0 = uhd.usrp_sink(
            ",".join(("serial=3297D84", "")),
            uhd.stream_args(
                cpu_format="fc32",
                args='',
                channels=list(range(0,1)),
            ),
            '',
        )
        self.uhd_usrp_sink_0.set_center_freq(4.9e9, 0)
        self.uhd_usrp_sink_0.set_gain(gain_transmit, 0)
        self.uhd_usrp_sink_0.set_antenna('TX/RX', 0)
        self.uhd_usrp_sink_0.set_samp_rate(1e6)
        # No synchronization enforced.
        self.qtgui_time_sink_x_0 = qtgui.time_sink_c(
            307200, #size
            samp_rate, #samp_rate
            "", #name
            1 #number of inputs
        )
        self.qtgui_time_sink_x_0.set_update_time(0.10)
        self.qtgui_time_sink_x_0.set_y_axis(-1, 1)

        self.qtgui_time_sink_x_0.set_y_label('Amplitude', "")

        self.qtgui_time_sink_x_0.enable_tags(True)
        self.qtgui_time_sink_x_0.set_trigger_mode(qtgui.TRIG_MODE_FREE, qtgui.TRIG_SLOPE_POS, 0.0, 0, 0, "")
        self.qtgui_time_sink_x_0.enable_autoscale(False)
        self.qtgui_time_sink_x_0.enable_grid(False)
        self.qtgui_time_sink_x_0.enable_axis_labels(True)
        self.qtgui_time_sink_x_0.enable_control_panel(False)
        self.qtgui_time_sink_x_0.enable_stem_plot(False)


        labels = ['Signal 1', 'Signal 2', 'Signal 3', 'Signal 4', 'Signal 5',
            'Signal 6', 'Signal 7', 'Signal 8', 'Signal 9', 'Signal 10']
        widths = [1, 1, 1, 1, 1,
            1, 1, 1, 1, 1]
        colors = ['blue', 'red', 'green', 'black', 'cyan',
            'magenta', 'yellow', 'dark red', 'dark green', 'dark blue']
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0, 1.0]
        styles = [1, 1, 1, 1, 1,
            1, 1, 1, 1, 1]
        markers = [-1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1]


        for i in range(2):
            if len(labels[i]) == 0:
                if (i % 2 == 0):
                    self.qtgui_time_sink_x_0.set_line_label(i, "Re{{Data {0}}}".format(i/2))
                else:
                    self.qtgui_time_sink_x_0.set_line_label(i, "Im{{Data {0}}}".format(i/2))
            else:
                self.qtgui_time_sink_x_0.set_line_label(i, labels[i])
            self.qtgui_time_sink_x_0.set_line_width(i, widths[i])
            self.qtgui_time_sink_x_0.set_line_color(i, colors[i])
            self.qtgui_time_sink_x_0.set_line_style(i, styles[i])
            self.qtgui_time_sink_x_0.set_line_marker(i, markers[i])
            self.qtgui_time_sink_x_0.set_line_alpha(i, alphas[i])

        self._qtgui_time_sink_x_0_win = sip.wrapinstance(self.qtgui_time_sink_x_0.pyqwidget(), Qt.QWidget)
        self.top_layout.addWidget(self._qtgui_time_sink_x_0_win)
        self.interp_fir_filter_xxx_0 = filter.interp_fir_filter_ccc(10, Lowpass)
        self.interp_fir_filter_xxx_0.declare_sample_delay(0)
        self._gain_lowpass2_range = Range(0, 15, 1, 5, 200)
        self._gain_lowpass2_win = RangeWidget(self._gain_lowpass2_range, self.set_gain_lowpass2, 'gain_lowpass2', "counter_slider", float)
        self.top_layout.addWidget(self._gain_lowpass2_win)
        self._gain_lowpass1_range = Range(0, 15, 1, 5, 200)
        self._gain_lowpass1_win = RangeWidget(self._gain_lowpass1_range, self.set_gain_lowpass1, 'gain_lowpass1', "counter_slider", float)
        self.top_layout.addWidget(self._gain_lowpass1_win)
        self.fir_filter_xxx_0 = filter.fir_filter_ccc(10, Lowpass2)
        self.fir_filter_xxx_0.declare_sample_delay(0)
        self.epy_block_0 = epy_block_0.blk()
        self.blocks_vector_source_x_0_0 = blocks.vector_source_f(self.sin_imag, True, 1, [])
        self.blocks_vector_source_x_0 = blocks.vector_source_f(self.sin_real, True, 1, [])
        self.blocks_throttle_1_0 = blocks.throttle(gr.sizeof_gr_complex*1, samp_rate,True)
        self.blocks_multiply_const_vxx_0 = blocks.multiply_const_cc(volume)
        self.blocks_head_0 = blocks.head(gr.sizeof_gr_complex*1, 307200)
        self.blocks_float_to_complex_0 = blocks.float_to_complex(1)


        ##################################################
        # Connections
        ##################################################
        self.connect((self.blocks_float_to_complex_0, 0), (self.blocks_multiply_const_vxx_0, 0))
        self.connect((self.blocks_head_0, 0), (self.epy_block_0, 0))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.interp_fir_filter_xxx_0, 0))
        self.connect((self.blocks_throttle_1_0, 0), (self.blocks_head_0, 0))
        self.connect((self.blocks_vector_source_x_0, 0), (self.blocks_float_to_complex_0, 0))
        self.connect((self.blocks_vector_source_x_0_0, 0), (self.blocks_float_to_complex_0, 1))
        self.connect((self.epy_block_0, 0), (self.qtgui_time_sink_x_0, 0))
        self.connect((self.fir_filter_xxx_0, 0), (self.blocks_throttle_1_0, 0))
        self.connect((self.interp_fir_filter_xxx_0, 0), (self.uhd_usrp_sink_0, 0))
        self.connect((self.uhd_usrp_source_0, 0), (self.fir_filter_xxx_0, 0))


    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "SSB_USRP")
        self.settings.setValue("geometry", self.saveGeometry())
        event.accept()

    def get_gain_lowpass2(self):
        return self.gain_lowpass2

    def set_gain_lowpass2(self, gain_lowpass2):
        self.gain_lowpass2 = gain_lowpass2
        self.set_Lowpass2(firdes.low_pass(self.gain_lowpass2, 1e6, 20e3, 1e3, firdes.WIN_HAMMING, 6.76))

    def get_gain_lowpass1(self):
        return self.gain_lowpass1

    def set_gain_lowpass1(self, gain_lowpass1):
        self.gain_lowpass1 = gain_lowpass1
        self.set_Lowpass(firdes.low_pass(self.gain_lowpass1, 1e6, 30e3, 1e3, firdes.WIN_HAMMING, 6.76))

    def get_volume(self):
        return self.volume

    def set_volume(self, volume):
        self.volume = volume
        self.blocks_multiply_const_vxx_0.set_k(self.volume)

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.blocks_throttle_1_0.set_sample_rate(self.samp_rate)
        self.qtgui_time_sink_x_0.set_samp_rate(self.samp_rate)

    def get_gain_transmit(self):
        return self.gain_transmit

    def set_gain_transmit(self, gain_transmit):
        self.gain_transmit = gain_transmit
        self.uhd_usrp_sink_0.set_gain(self.gain_transmit, 0)

    def get_gain_receive(self):
        return self.gain_receive

    def set_gain_receive(self, gain_receive):
        self.gain_receive = gain_receive
        self.uhd_usrp_source_0.set_gain(self.gain_receive, 0)

    def get_Lowpass2(self):
        return self.Lowpass2

    def set_Lowpass2(self, Lowpass2):
        self.Lowpass2 = Lowpass2
        self.fir_filter_xxx_0.set_taps(self.Lowpass2)

    def get_Lowpass(self):
        return self.Lowpass

    def set_Lowpass(self, Lowpass):
        self.Lowpass = Lowpass
        self.interp_fir_filter_xxx_0.set_taps(self.Lowpass)





def main(top_block_cls=SSB_USRP, options=None):

    if StrictVersion("4.5.0") <= StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls()

    tb.start()

    tb.show()

    def sig_handler(sig=None, frame=None):
        Qt.QApplication.quit()

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    timer = Qt.QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)

    def quitting():
        tb.stop()
        tb.wait()

    qapp.aboutToQuit.connect(quitting)
    qapp.exec_()

if __name__ == '__main__':
    eng = matlab.engine.start_matlab()
    main()
