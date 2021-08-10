class CueTime
  attr_accessor :frames

  MAX_MINUTES = 999
  MAX_SECONDS = 59
  MAX_FRAMES = 74
  MAX_TOTAL_FRAMES = MAX_MINUTES * (MAX_SECONDS + 1) * (MAX_FRAMES + 1) +
                      MAX_SECONDS * (MAX_FRAMES + 1)  + (MAX_FRAMES)

  def initialize(time_str = nil)
    @frames = time_str.nil? ? 0 : parse_time(time_str)
    validate_frames
  end

  def self.to_str(full: false, frames:)
    frames_sign = frames < 0 ? '-' : ''
    time_arr = split_time(frames)
    template = if time_arr.first > 99 || full
                 '%s%d:%02d:%02d'
               else
                 '%s%02d:%02d:%02d'
               end
    time_arr.insert(0, frames_sign)
    sprintf(template, *time_arr )
  end

  def to_str(full: false, frames: @frames)
    self.class.to_str(full: full, frames: frames)
  end

  alias to_s to_str

  def -(time)
    frames = get_frames(time)
    self.class.validate_frames(@frames - frames)
    @frames -= frames
    self
  end

  def +(time)
    frames = get_frames(time)
    self.class.validate_frames(@frames + frames)
    @frames += frames
    self
  end

  def <=(time)
    @frames <= get_frames(time)
  end

  def <(time)
    @frames < get_frames(time)
  end

  def >(time)
    @frames > get_frames(time)
  end

  def >=(time)
    @frames >= get_frames(time)
  end

  private

  # calculates and returns only positive numbers
  def self.split_time(frames)
    seconds, frames = frames.abs.divmod(MAX_FRAMES + 1)
    minutes, seconds = seconds.divmod(MAX_SECONDS + 1)
    [minutes, seconds, frames]
  end

  def get_frames(time)
    if time.instance_of? self.class
      time.frames
    else
      self.class.validate_format_time_str(time)
      parse_time(time)
    end
  end

  def parse_time(time_str)
    self.class.validate_format_time_str(time_str)

    time_arr = if time_str.include?('.')
                 format_ms_to_frames(time_str)
               else
                 time_str.split(":").map!(&:to_i)
               end

    if time_arr.size < 3
      time_arr = Array.new(3 - time_arr.size, 0) + time_arr
    end

    self.class.validate_str(*time_arr)
    time_arr.reverse!

    frames = 0
    frames += time_arr.delete_at(0)
    frames += time_arr.delete_at(0) * (MAX_FRAMES + 1)
    frames += time_arr.delete_at(0) * (MAX_SECONDS + 1) * (MAX_FRAMES + 1)
  end


  def format_ms_to_frames(time_str)
    arr = time_str.split(/[:.]/).map!(&:to_i)
    arr[-1] = (arr.last.to_i / 13.334).floor
    if arr.size == 4
      hours = arr.shift
      arr[0] += hours * 60
    end
    arr.map!(&:to_i)
  end

  def self.validate_frames(frames)
    if frames > MAX_TOTAL_FRAMES
      raise "Error! Exceeded the maximum possible time in the CUE: #{to_str(frames: frames)}" +
              validate_max_value_message
    elsif frames < 0
      raise "Error! You can't get a negative time! #{to_str(frames: frames)}" + validate_max_value_message
    end
  end

  def validate_frames
    self.class.validate_frames(@frames)
  end

  def self.validate_format_time_str(time_str)
    format_w_frames = /^([0-9]{1,3}:)?[0-9]{2}:[0-9]{2}$/
    format_w_ms = /^([0-9]{1,2}:)?[0-9]{1,2}:[0-9]{2}\.[0-9]{1,3}$/

    unless  time_str =~ format_w_frames || time_str =~ format_w_ms
      raise "Time validation failed: #{time_str}" +
            "\nValid string time format: 111:11:11 or 01:10" +
            validate_max_value_message +
            "\nor time with ms: 10:04:06.000 or 2:59.640" +
            validate_max_value_message_ms
    end
    true
  end

  def self.validate_raise(minutes, seconds, frames)
    raise "Time validation failed: minutes: #{minutes}, seconds: #{seconds}, frames: #{frames}" +
            validate_max_value_message
  end

  def self.validate_max_value_message
    times = %w(Minutes Seconds Frames)
    maxs  = [MAX_MINUTES, MAX_SECONDS, MAX_FRAMES]

    times.zip(maxs).to_h.map do |key, value|
      format("%s%-10s %s", "\n\t", key, "<= #{value}")
    end.join
  end

  def self.validate_max_value_message_ms
    times = %w(Hours Minutes Seconds Ms)
    maxs  = [16, 60, MAX_SECONDS, 999]

    times.zip(maxs).to_h.map do |key, value|
      format("%s%-10s %s", "\n\t", key, "<= #{value}")
    end.join
  end

  def self.validate_str(minutes, seconds, frames)
    unless minutes_valid?(minutes) && seconds_valid?(seconds) && frames_valid?(frames)
      validate_raise(minutes, seconds, frames)
    end
    true
  end

  def self.frames_valid?(frames)
    frames <= MAX_FRAMES && frames >= 0
  end

  def self.seconds_valid?(seconds)
    seconds <= MAX_SECONDS && seconds >= 0
  end

  def self.minutes_valid?(minutes)
    minutes <= MAX_MINUTES && minutes >= 0
  end
end
