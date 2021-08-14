require_relative 'rspec_helper'
load_class(__FILE__)

describe CueTime do
  def get_frames(str)
    frames_max = 75
    time_arr = str.split(':').map!(&:to_i)

    if time_arr.size < 3
      time_arr = Array.new(3 - time_arr.size, 0) + time_arr
    end
    time_arr.reverse!
    # [frames, seconds, minutes]
    time_arr[0] + time_arr[1] * frames_max + time_arr[2] * 60 * frames_max
  end

  def get_frames_ms(str_ms)
    frames_max = 75
    time_arr = str_ms.split(/[:.]/).map!(&:to_i)

    # 1000 ms == 75 frames
    k = 1000 / 75.0
    time_arr[-1] = (time_arr.last.to_i / k).floor

    if time_arr.size == 4
      hours = time_arr.shift
      time_arr[0] += hours * 60
    end
    time_arr.reverse!
    # [frames, seconds, minutes]
    time_arr[0] + time_arr[1] * frames_max + time_arr[2] * 60 * frames_max
  end

  describe "#new" do
    it "#new w/o arg create object with 0 frames" do
      expect(CueTime.new.frames).to eq 0
    end

    it "#new w correct arg create object w correct number of frames" do
      args = %w(00:00 72:43:11 018:42:00 000:14:12 702:00:74 316:59:68)

      args.each do |arg|
        expect(CueTime.new(arg).frames).to eq get_frames(arg)
      end
    end

    it "#new w incorrect arg return raise CueTimeInvalidFormat w msg" do
      args = %w(-00:00 018:60:00 000:14:75 702:00:80 316:100:68 weqwe 316:100;68 316.100:68 702:OO:80 5940:60:74 99:01:60.987)

      args.each do |arg|
        msg = "Time validation failed \"#{arg}\""
        expect{ CueTime.new(arg) }.to raise_error(CueTimeInvalidFormat).with_message(/#{msg}/)
      end
    end

    it "#new w correct ms-format arg create object w correct number of frames" do
      args = %w(98:00:59.973 2:31:59.999 2:31:59.0 2:31:59.000 2:59:00.25 2:00:00.014 22:03.013 0:00:00.001)

      puts "\tAttention! Converting MS to FRAMES it won't be lossless! since 1 frame is equal to 13.3(3) ms."
      puts "\tThe fractional part is reclined, so the rounding goes downwards."
      puts "\t"
      puts "\tExamples convert ms => frame => ms"
      puts format("\t%-17s => %-10s => %-18s OR %-15s",
                  'input ms-format', 'frame', 'time frame-format', 'time ms-format')
      args.each do |arg|
        time = CueTime.new(arg)
        puts format("\t%-17s => %-10s => %-18s => %-15s", arg, get_frames_ms(arg), time, time.to_str_ms)
        expect(CueTime.new(arg).frames).to eq get_frames_ms(arg)
      end
    end

    it "#new w arg eq max time create object w correct number of frames" do
      args = [CueTime.to_str(frames: CueTime::MAX_TOTAL_FRAMES), CueTime.to_str(mode: :ms, frames: CueTime::MAX_TOTAL_FRAMES)]

      args.each do |arg|
        expect(CueTime.new(arg).frames).to eq CueTime::MAX_TOTAL_FRAMES
      end
    end

    it "#new w arg > maximum allowed time return raise CueTimeMaxValue w msg" do
      args = %w(99:00:00.014 99:00:01.000 99:01:00.000 6000:43:11 5940:00:01 5940:01:00 5941:01:00 6941:01:00)

      args.each do |arg|
        msg = "Error! Exceeded the maximum possible time in the CUE"
        expect{ CueTime.new(arg) }.to raise_error(CueTimeMaxValue).with_message(/#{msg}/)
      end
    end
  end

  describe ".to_str" do
    it ".to_str(frames: N) w correct arg return correct short format w/o leading zero in minutes" do
      args       = %w(  00:00 72:43:11 018:42:00 000:04:12 702:00:74 316:59:68)
      args_short = %w(0:00:00 72:43:11  18:42:00   0:04:12 702:00:74 316:59:68)

      args.each_with_index do |arg, idx|
        expect(CueTime.to_str(frames: CueTime.new(arg).frames)).to eq args_short[idx]
      end
    end

    it ".to_str(mode: :full, frames: N) return correct full time format w leading zero in minutes" do
      args       = %w(000:00:00  72:43:11   8:42:00 001:14:12     00:74 316:59:68)
      args_short = %w(000:00:00 072:43:11 008:42:00 001:14:12 000:00:74 316:59:68)

      args.each_with_index do |arg, idx|
        expect(CueTime.to_str(mode: :full, frames: CueTime.new(arg).frames)).to eq args_short[idx]
      end
    end

    it ".to_str(frames: N) w incorrect arg return raise CueTimeInvalidFormat w msg" do
      args = %w(72:43 Raiden -0 -00 000 +213)

      args.each do |arg|
        msg = "Validate frames error #{arg}! Frames can only be a number."
        expect{ CueTime.to_str(frames: arg) }.to raise_error(CueTimeInvalidFormat)
                                                       .with_message(msg)
      end
    end

    it ".to_str(frames: N) save sign - after convert" do
      args = %w(0 -213 32423 -45487)

      args.each do |arg|
        expect(CueTime.to_str(frames: arg)[/^[-]/, 0]).to eq arg[/^[-]/, 0]
      end
    end

    it ".to_str(mode: :ms, frames: N) return correct time ms-format" do
      args_ms      = %w(15:31:59.999 02:31:59.0   2:31:59.000   2:59:00.025   2:00:00.014    22:03.013 0:00:00.001)
      valid_output = %w(15:31:59.987  2:31:59.000 2:31:59.000   2:59:00.013   2:00:00.013  0:22:03.000 0:00:00.000)

      args_ms.each_with_index do |arg, idx|
        frames = CueTime.new(arg).frames
        expect(CueTime.to_str(mode: :ms, frames: frames)).to eq valid_output[idx]
      end
    end
  end

  describe "#to_str" do
    it "#to_str return correct time short format w/o leading zero in minutes" do
      args       = %w(00:00   072:43:11 008:42:00 000:14:12 702:00:74 316:59:68)
      args_short = %w(0:00:00  72:43:11   8:42:00   0:14:12 702:00:74 316:59:68)

      args.each_with_index do |arg, idx|
        expect(CueTime.new(arg).to_str).to eq args_short[idx]
      end
    end

    it "#to_str(mode: :full) return correct full time format w leading zero in minutes" do
      args       = %w(000:00:00  72:43:11   8:42:00 001:14:12     00:74 316:59:68)
      args_short = %w(000:00:00 072:43:11 008:42:00 001:14:12 000:00:74 316:59:68)

      args.each_with_index do |arg, idx|
        expect(CueTime.new(arg).to_str(mode: :full)).to eq args_short[idx]
      end
    end

    it "#to_str(frames: N) w correct arg return correct short format w/o leading zero in minutes" do
      args       = %w(  00:00 72:43:11 018:42:00 000:04:12 702:00:74 316:59:68)
      args_short = %w(0:00:00 72:43:11  18:42:00   0:04:12 702:00:74 316:59:68)

      args.each_with_index do |arg, idx|
        expect(CueTime.new.to_str(frames: CueTime.new(arg).frames)).to eq args_short[idx]
      end
    end

    it "#to_str(frames: N) w incorrect arg return raise CueTimeInvalidFormat w msg" do
      args = %w(72:43 Raiden -0 -00 000 +213)

      args.each do |arg|
        msg = "Validate frames error #{arg}! Frames can only be a number."
        expect{ CueTime.new.to_str(frames: arg) }.to raise_error(CueTimeInvalidFormat)
                                                                           .with_message(msg)
      end
    end

    it "#to_str(frames: N) save sign - after convert" do
      args = %w(0 -213 32423 -45487)

      args.each do |arg|
        expect(CueTime.new.to_str(frames: arg)[/^[-]/, 0]).to eq arg[/^[-]/, 0]
      end
    end

    it "#to_str(mode: :full, frames: N) return correct full time format w leading zero in minutes" do
      args       = %w(000:00:00  72:43:11   8:42:00 001:14:12     00:74 316:59:68)
      args_short = %w(000:00:00 072:43:11 008:42:00 001:14:12 000:00:74 316:59:68)

      args.each_with_index do |arg, idx|
        frames = CueTime.new(arg).frames
        expect(CueTime.new.to_str(mode: :full, frames: frames)).to eq args_short[idx]
      end
    end
  end

  describe "#to_str_ms" do

    # to_str_ms alias to_str(mode: :ms)
    args_ms      = %w(15:31:59.999 02:31:59.0   2:31:59.000   2:59:00.025   2:00:00.014    22:03.013 0:00:00.001)
    valid_output = %w(15:31:59.987  2:31:59.000 2:31:59.000   2:59:00.013   2:00:00.013  0:22:03.000 0:00:00.000)

    it "#to_str_ms return correct time in ms-format" do
      args_ms.each_with_index do |arg, idx|
        expect(CueTime.new(arg).to_str_ms).to eq valid_output[idx]
      end
    end

    it "#to_str(mode: :ms) return correct time in ms-format" do
      args_ms.each_with_index do |arg, idx|
        expect(CueTime.new(arg).to_str(mode: :ms)).to eq valid_output[idx]
      end
    end
  end

  describe "#+" do
    args         = %w(  00:00  72:43:21 059:42:01 000:14:12 102:59:74 316:59:74)
    args2        = %w(  00:00   0:06:64   0:59:74 000:14:12 702:11:00  13:59:74)
    valid_output = %w(0:00:00  72:50:10  60:42:00   0:28:24 805:10:74 330:59:73)

    it "#+ arg as string" do
      args.each_with_index do |arg, idx|
        expect((CueTime.new(arg) + args2[idx]).to_str).to eq valid_output[idx]
      end
    end

    it "#+ arg as instance CueTime" do
      args.each_with_index do |arg, idx|
        expect( ( CueTime.new(arg) + CueTime.new(args2[idx]) ).to_str ).to eq valid_output[idx]
      end
    end

    it "#+ with arg exceeding the maximum return raise CueTimeMaxValue w msg" do
      args  = %w( 5000:59:74  5940:59:74  5940:59:74 )
      args2 = %w(  941:43:00     0:01:00     0:00:01 )

      args.each_with_index do |arg, idx|
        msg = "Error! Exceeded the maximum possible time in the CUE:"
        expect{ CueTime.new(arg) + CueTime.new(args2[idx]) }.to raise_error(CueTimeMaxValue)
                                                                  .with_message(/#{msg}/)
      end
    end
  end

  describe "#-" do
    args         = %w(0:00:00  72:50:10  60:42:00   0:28:24 805:10:74 330:59:73)
    args2        = %w(  00:00  72:43:21 059:42:01 000:14:12 102:59:74 316:59:74)
    valid_output = %w(0:00:00   0:06:64   0:59:74   0:14:12 702:11:00  13:59:74)

    it "#- arg as string" do
      args.each_with_index do |arg, idx|
        expect((CueTime.new(arg) - args2[idx]).to_str).to eq valid_output[idx]
      end
    end

    it "#- arg as instance CueTime" do
      args.each_with_index do |arg, idx|
        expect( ( CueTime.new(arg) - CueTime.new(args2[idx]) ).to_str ).to eq valid_output[idx]
      end
    end

    it "#- with arg exceeding the instance time return raise CueTimeNegative w msg" do
      args  = %w( 72:50:73  60:42:00  330:59:73 )
      args2 = %w( 72:50:74  60:43:00  331:59:73 )

      args.each_with_index do |arg, idx|
        msg = "Error! You can't get a negative time!"
        expect{ CueTime.new(arg) - CueTime.new(args2[idx]) }.to raise_error(CueTimeNegative)
                                                                     .with_message(/#{msg}/)
      end
    end
  end

  describe "#>" do
    args         = %w(0:00:00  72:50:10  60:42:00   0:28:74 100:59:74 330:59:74)
    args2        = %w(  00:00  72:43:21 059:42:01 000:29:74 100:59:74 330:59:73)
    valid_output = %w(  false      true      true     false     false      true)

    it "#> arg as string" do
      args.each_with_index do |arg, idx|
        expect( CueTime.new(arg) > args2[idx] ).to eq valid_output[idx] == "true"
      end
    end

    it "#> arg as instance CueTime" do
      args.each_with_index do |arg, idx|
        expect( CueTime.new(arg) > CueTime.new(args2[idx]) ).to eq valid_output[idx] == "true"
      end
    end
  end

  describe "#<" do
    args         = %w(0:00:00  72:50:10  60:42:00   0:28:74 100:59:74 330:59:74)
    args2        = %w(  00:00  72:43:21 059:42:01 000:29:74 100:59:74 330:59:73)
    valid_output = %w(  false    false      false      true     false     false)

    it "#< arg as string" do
      args.each_with_index do |arg, idx|
        expect( CueTime.new(arg) < args2[idx] ).to eq valid_output[idx] == "true"
      end
    end

    it "#< arg as instance CueTime" do
      args.each_with_index do |arg, idx|
        expect( CueTime.new(arg) < CueTime.new(args2[idx]) ).to eq valid_output[idx] == "true"
      end
    end
  end

  describe "#<=" do
    args         = %w(0:00:00  72:50:10  60:42:00   0:28:74 100:59:74 330:59:74)
    args2        = %w(  00:00  72:43:21 059:42:01 000:29:74 100:59:74 330:59:73)
    valid_output = %w(   true    false      false      true      true     false)

    it "#< arg as string" do
      args.each_with_index do |arg, idx|
        expect( CueTime.new(arg) <= args2[idx] ).to eq valid_output[idx] == "true"
      end
    end

    it "#< arg as instance CueTime" do
      args.each_with_index do |arg, idx|
        expect( CueTime.new(arg) <= CueTime.new(args2[idx]) ).to eq valid_output[idx] == "true"
      end
    end
  end

  describe "#>=" do
    args         = %w(0:00:00  72:50:10  60:42:00   0:28:74 100:59:74 330:59:74)
    args2        = %w(  00:00  72:43:21 059:42:01 000:29:74 100:59:74 330:59:73)
    valid_output = %w(   true      true      true     false      true      true)

    it "#> arg as string" do
      args.each_with_index do |arg, idx|
        expect( CueTime.new(arg) >= args2[idx] ).to eq valid_output[idx] == "true"
      end
    end

    it "#> arg as instance CueTime" do
      args.each_with_index do |arg, idx|
        expect( CueTime.new(arg) >= CueTime.new(args2[idx]) ).to eq valid_output[idx] == "true"
      end
    end
  end
end
