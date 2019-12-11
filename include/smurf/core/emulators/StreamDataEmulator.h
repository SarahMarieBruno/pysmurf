#ifndef _SMURF_CORE_EMULATORS_STREAMDATAEMULATOR_H_
#define _SMURF_CORE_EMULATORS_STREAMDATAEMULATOR_H_

/**
 *-----------------------------------------------------------------------------
 * Title         : SMuRF Data Emulator
 * ----------------------------------------------------------------------------
 * File          : StreamDataEmulator.h
 * Created       : 2019-10-28
 *-----------------------------------------------------------------------------
 * Description :
 *    SMuRF Data StreamDataEmulator Class
 *-----------------------------------------------------------------------------
 * This file is part of the smurf software platform. It is subject to
 * the license terms in the LICENSE.txt file found in the top-level directory
 * of this distribution and at:
    * https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
 * No part of the smurf software platform, including this file, may be
 * copied, modified, propagated, or distributed except according to the terms
 * contained in the LICENSE.txt file.
 *-----------------------------------------------------------------------------
**/

#include <rogue/interfaces/stream/Frame.h>
#include <rogue/interfaces/stream/FrameLock.h>
#include <rogue/interfaces/stream/FrameIterator.h>
#include <rogue/interfaces/stream/FrameAccessor.h>
#include <rogue/interfaces/stream/Buffer.h>
#include <rogue/interfaces/stream/Slave.h>
#include <rogue/interfaces/stream/Master.h>
#include <rogue/GilRelease.h>
#include <rogue/Logging.h>
#include "smurf/core/common/SmurfHeader.h"
#include "smurf/core/common/Helpers.h"
#include <random>

namespace bp  = boost::python;
namespace ris = rogue::interfaces::stream;

namespace smurf
{
    namespace core
    {
        namespace emulators
        {
            class StreamDataEmulator;
            typedef std::shared_ptr<StreamDataEmulator> StreamDataEmulatorPtr;

            class StreamDataEmulator : public ris::Slave, public ris::Master
            {
            private:
                // Data types
                typedef int16_t fw_t;   // Data type from firmware

            public:
                StreamDataEmulator();
                ~StreamDataEmulator() {};

                static StreamDataEmulatorPtr create();

                static void setup_python();

                // Accept new frames
                void acceptFrame(ris::FramePtr frame);

                // Disable the processing block. The data
                // will just pass through to the next slave
                void       setDisable(bool d);
                const bool getDisable() const;

                // Set/Get operation mode
                void      setType(int value);
                const int getType() const;

                // Set/Get signal amplitude
                void       setAmplitude(fw_t value);
                const fw_t getAmplitude() const;

                // Set/Get signal offset
                void       setOffset(fw_t value);
                const fw_t getOffset() const;

                // Set/Get  signal period
                void              setPeriod(std::size_t value);
                const std::size_t getPeriod() const;

            private:
                // Types of signal
                enum class SignalType { Zeros, ChannelNumber, Random, Square, Sawtooth, Triangle, Sine, DropFrame, Size };

                // Maximum amplitud value (2^(#bit of fw_t - 1) - 1)
                const fw_t maxAmplitude = (1 << (8*sizeof(fw_t) - 1)) - 1;

                // Signal generator methods
                void genZeroWave(ris::FrameAccessor<fw_t> &dPtr)          const;
                void genChannelNumberWave(ris::FrameAccessor<fw_t> &dPtr) const;
                void genRandomWave(ris::FrameAccessor<fw_t> &dPtr);
                void genSquareWave(ris::FrameAccessor<fw_t> &dPtr);
                void getSawtoothWave(ris::FrameAccessor<fw_t> &dPtr);
                void genTriangleWave(ris::FrameAccessor<fw_t> &dPtr);
                void genSinWave(ris::FrameAccessor<fw_t> &dPtr);
                void genFrameDrop();

                // Logger
                std::shared_ptr<rogue::Logging> eLog_;

                // Mutex
                std::mutex  mtx_;

                // Variables
                bool        disable_;       // Disable flag
                SignalType  type_;          // signal type
                fw_t        amplitude_;     // Signal amplitude
                fw_t        offset_;        // Signal offset
                std::size_t period_;        // Signal period
                std::size_t periodCounter_; // Frame period counter
                bool        dropFrame_;     // Flag to indicate if the frame should be dropped

                // Variables use to generate random numbers
                std::random_device                     rd;  // Will be used to obtain a seed for the random number engine
                std::mt19937                           gen; // Standard mersenne_twister_engine seeded with rd()
                std::uniform_real_distribution<double> dis; // Use to transform the random unsigned int generated by gen into a double

            };
        }
    }
}

#endif
