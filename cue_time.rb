class CueTime
  attr_reader :frames

  MAX_MINUTES = 999
  MAX_SECONDS = 59
  MAX_FRAMES = 74
  MAX_TOTAL_FRAMES = MAX_MINUTES * (MAX_SECONDS + 1) * (MAX_FRAMES + 1) + (MAX_SECONDS + 1) + (MAX_FRAMES + 1)

  def initialize(time_str)
    @frames = parse_time(time_str)
    validate_frames(@frames)
  end

  def to_str(full: false, frames: @frames)
    time_arr = split_time(frames)
    template = if time_arr.first > 99 || full
                 '%d:%02d:%02d'
               else
                 '%02d:%02d:%02d'
               end
    sprintf(template, *time_arr )
  end

  alias to_s to_str

  def -(time)
    frames = get_frames(time)
    validate_frames(@frames - frames)
    @frames -= frames
    to_str
  end

  def +(time)
    frames = get_frames(time)
    validate_frames(@frames + frames)
    @frames += frames
    to_str
  end

  def <(time)
    @frames < get_frames(time)
  end

  def >(time)
    @frames > get_frames(time)
  end

  private

  def split_time(frames)
    seconds, frames = frames.divmod(MAX_FRAMES + 1)
    minutes, seconds = seconds.divmod(MAX_SECONDS + 1)
    [minutes, seconds, frames]
  end

  def get_frames(time)
    if time.instance_of? self.class
      time.frames
    else
      validate_format_time_str(time)
      parse_time(time)
    end
  end

  def parse_time(time_str)
    validate_format_time_str(time_str)

    time_arr = time_str.split(":").map!(&:to_i)
    if time_arr.size < 3
      time_arr = Array.new(3 - time_arr.size, 0) + time_arr
    end

    validate_str(*time_arr)
    time_arr.reverse!

    frames = 0
    frames += time_arr.delete_at(0)
    frames += time_arr.delete_at(0) * (MAX_FRAMES + 1)
    frames += time_arr.delete_at(0) * (MAX_SECONDS + 1) * (MAX_FRAMES + 1)
  end

  def validate_frames(frames)
    if frames > MAX_TOTAL_FRAMES
      raise "Error! Exceeded the maximum possible time in the CUE: #{self.to_str(frames: frames)}" +
              validate_max_value_message
    elsif frames < 0
      raise "Error! You can't get a negative time! #{self.to_str(frames: frames)}" + validate_max_value_message
    end
  end

  def validate_format_time_str(time_str)
    unless  time_str =~ /^([0-9]{1,3}:)?[0-9]{2}:[0-9]{2}$/
      raise "Time validation failed: #{time_str}" +
              "\nValid string time format: 111:11:11 or 11:11" +
              validate_max_value_message
    end
    true
  end

  def validate_raise(minutes, seconds, frames)
    raise "Time validation failed: minutes: #{minutes}, seconds: #{seconds}, frames: #{frames}" +
            validate_max_value_message
  end

  def validate_max_value_message
    "\nMinutes must be <= #{MAX_MINUTES}" +
      "\nSeconds must be <= #{MAX_SECONDS}" +
      "\nFrames must be <= #{MAX_FRAMES}"
  end

  def validate_str(minutes, seconds, frames)
    unless minutes_valid?(minutes) && seconds_valid?(seconds) && frames_valid?(frames)
      validate_raise(minutes, seconds, frames)
    end
    true
  end

  def frames_valid?(frames)
    frames <= MAX_FRAMES && frames >= 0
  end

  def seconds_valid?(seconds)
    seconds <= MAX_SECONDS && seconds >= 0
  end

  def minutes_valid?(minutes)
    minutes <= MAX_MINUTES && minutes >= 0
  end
end
