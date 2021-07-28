class CueTime
  attr_reader :minutes, :seconds, :frames

  MAX_MINUTES = 999
  MAX_SECONDS = 59
  MAX_FRAMES = 74

  def initialize(time_str)
    @minutes, @seconds, @frames = parse_time(time_str)
    validate
  end

  def to_str(full = false)
    template = if @minutes > 99 || full
                 '%d:%02d:%02d'
               else
                 '%02d:%02d:%02d'
               end
    sprintf(template, @minutes, @seconds, @frames )
  end

  alias to_s to_str

  # можно реализовать по другому приводить время к общему кол-ву фреймов
  # вычитать складывать и потом форматировать результат в '%02d:%02d:%02d'
  def -(time)
    if time.instance_of? self.class
      minutes, seconds, frames = time.minutes, time.seconds, time.frames
    else
      minutes, seconds, frames = parse_time(time)
      validate_str(minutes: minutes, seconds: seconds, frames: frames)
    end

    frames_subtraction(frames)
    seconds_subtraction(seconds)
    minutes_subtraction(minutes)
    validate
    to_str
  end

  def +(time)
    if time.instance_of? self.class
      minutes, seconds, frames = time.minutes, time.seconds, time.frames
    else
      minutes, seconds, frames = parse_time(time)
      validate_str(minutes: minutes, seconds: seconds, frames: frames)
    end

    frames_summation(frames)
    seconds_summation(seconds)
    minutes_summation(minutes)
    validate
    to_str
  end

  private

  def parse_time(time_str)
    validate_format_time_str(time_str)
    time_arr = time_str.split(":")

    if time_arr.size < 3
      time_arr = Array.new(3 - time_arr.size, 0) + time_arr
    end

    time_arr.map(&:to_i)
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

  def validate
    unless minutes_valid?(@minutes) && minutes_valid?(@seconds) && frames_valid?(@frames)
      validate_raise(@minutes, @seconds, @frames)
    end
    true
  end

  def validate_str(minutes:, seconds:, frames:)

    unless minutes_valid?(minutes) && seconds_valid?(seconds) && frames_valid?(frames)
      validate_raise(minutes, frames, seconds)
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

  def frames_summation(frames)
    @frames += frames
    if @frames > MAX_FRAMES
      @frames = @frames - MAX_FRAMES - 1
      seconds_summation(1)
    end
  end
  def seconds_summation(seconds)
    @seconds += seconds
    if @seconds > MAX_SECONDS
      @seconds = @seconds - MAX_SECONDS - 1
      minutes_summation(1)
    end
  end

  def minutes_summation(minutes)
    @minutes += minutes
    if @minutes > MAX_MINUTES
      raise "Minutes cannot be more than #{MAX_MINUTES}! @minutes = #{@minutes}"
    end
  end

  def frames_subtraction(frames)
    if @frames >= frames
      @frames -= frames
    else
      @frames = MAX_FRAMES + 1 - frames + @frames
      seconds_subtraction(1)
    end
  end

  def seconds_subtraction(seconds)
    if @seconds >= seconds
      @seconds -= seconds
    else
      @seconds = MAX_SECONDS + 1 - seconds + @seconds
      minutes_subtraction(1)
    end
  end

  def minutes_subtraction(minutes)
    if @minutes >= minutes
      @minutes -= minutes
    else
      raise "You can't get a negative time! @minutes = #{@minutes} - #{minutes}"
    end
  end
end
