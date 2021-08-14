class CueTime
  attr_reader :frames

  MAX_HOURS_MS = 99
  MAX_MINUTES_MS = 59
  MAX_MS = 999
  #
  MAX_MINUTES = MAX_HOURS_MS * 60
  MAX_SECONDS = 59
  MAX_FRAMES = 74
  MAX_TOTAL_FRAMES = MAX_MINUTES * (MAX_SECONDS + 1) * (MAX_FRAMES + 1)

  def initialize(time_str = nil)
    @frames = time_str.nil? ? 0 : parse_time(time_str)
    validate_frames
  end

  def self.to_str(mode: false, frames:)
    unless is_number?(frames)
      raise CueTimeInvalidFormat, "Validate frames error #{frames}! Frames can only be a number."
    end

    frames_sign = frames.to_i < 0 ? '-' : ''
    time_arr = split_time(frames.to_i)
    template = if mode == :ms
                 time_arr = split_time_ms(frames.to_i)
                 '%s%d:%02d:%02d.%03d'
               elsif time_arr.first > 99 || mode == :full
                 '%s%03d:%02d:%02d'
               else
                 '%s%d:%02d:%02d'
               end
    time_arr.insert(0, frames_sign)
    format(template, *time_arr )
  end

  # FIXME нужен ли параметр frames внешне?
  def to_str(mode: false, frames: @frames)
    self.class.to_str(mode: mode, frames: frames)
  end

  def to_str_ms(frames: @frames)
    self.class.to_str(mode: :ms, frames: frames)
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

  def self.split_time_ms(frames)
    minutes, seconds, frames = *split_time(frames)
    hour, minutes = minutes.divmod(MAX_MINUTES_MS + 1)
    ms = frames * (1000 / 75.0)
    [hour, minutes, seconds, ms.round]
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

    time_arr.reverse!
    frames = 0
    frames += time_arr.delete_at(0)
    frames += time_arr.delete_at(0) * (MAX_FRAMES + 1)
    frames += time_arr.delete_at(0) * (MAX_SECONDS + 1) * (MAX_FRAMES + 1)

    self.class.validate_frames(frames)
  end

  def format_ms_to_frames(time_str)
    arr = time_str.split(/[:.]/).map!(&:to_i)

    # 1000 ms == 75 frames
    k = 1000 / 75.0
    arr[-1] = (arr.last.to_i / k).floor
    if arr.size == 4
      hours = arr.shift
      arr[0] += hours * 60
    end

    arr.map!(&:to_i)
  end

  def self.validate_frames(frames)
    if frames > MAX_TOTAL_FRAMES
      msg = "Error! Exceeded the maximum possible time in the CUE: #{to_str(frames: frames)}"
      raise CueTimeMaxValue, msg + valid_max_allowed_time_message
    elsif frames < 0
      msg = "Error! You can't get a negative time! #{to_str(frames: frames)}"
      raise CueTimeNegative, msg + valid_max_value_message_frames
    end
    frames
  end

  def validate_frames
    self.class.validate_frames(@frames)
  end

  def self.validate_format_time_str(time_str)
    format_w_frames = /^([0-9]{1,4}:)?[0-5][0-9]:([0-6][0-9]|7[0-4])$/
    format_w_ms     = /^([0-9]{1,2}:)?[0-5]?[0-9]:[0-5][0-9]\.[0-9]{1,3}/

    unless  time_str =~ format_w_frames || time_str =~ format_w_ms
      msg = "Time validation failed \"#{time_str}\""
      raise CueTimeInvalidFormat, msg + validate_max_values_message
    end
    true
  end

  def self.validate_max_values_message
    valid_max_value_message_frames +
    "\nOR" +
    valid_max_value_message_ms +
    valid_max_allowed_time_message
  end

  def self.valid_max_value_message_frames
    times = %w(Minutes Seconds Frames)
    maxs  = [MAX_MINUTES, MAX_SECONDS, MAX_FRAMES]

    head = "\nValid string time format: 111:01:11 or 01:10"
    limits = times.zip(maxs).to_h.map do |key, value|
      format("%s%-10s %s", "\n\t", key, "<= #{value}")
    end.join

    head + limits
  end

  def self.valid_max_value_message_ms
    times = %w(Hours Minutes Seconds Ms)
    maxs  = [MAX_HOURS_MS, MAX_MINUTES_MS, MAX_SECONDS, MAX_MS]

    head = "\nValid time with ms: 10:04:06.000 or 2:59.640"
    limits = times.zip(maxs).to_h.map do |key, value|
      format("%s%-10s %s", "\n\t", key, "<= #{value}")
    end.join

    head + limits
  end

  def self.valid_max_allowed_time_message
    max_frame_format = CueTime.to_str(frames: MAX_TOTAL_FRAMES)
    max_ms_format    = CueTime.to_str(mode: :ms, frames: MAX_TOTAL_FRAMES)
    "\nMax Allowed Time: #{max_frame_format} or #{max_ms_format}"
  end

  def self.is_number?(n)
    n.to_f.to_s == n.to_s || n.to_i.to_s == n.to_s
  end
end
