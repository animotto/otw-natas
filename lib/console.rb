class Console
  CSI       = "\e\x1b["
  SGR       = "m"
  RESET     = 0
  BOLD      = 1
  COLOR_FG  = 30
  COLOR_BG  = 40

  STYLES    = {
    reset:          0,
    bold:           1,
    dim:            2,
    italic:         3,
    underline:      4,
    blink:          5,
    inverse:        7,
    hidden:         8,
    strikethrough:  9,
  }

  COLORS    = {
    black:    0,
    red:      1,
    green:    2,
    yellow:   3,
    blue:     4,
    magenta:  5,
    cyan:     6,
    white:    7,
  }

  def initialize
    @sgr = Array.new
  end

  def method_missing(method, *args)
    if STYLES.key?(method)
      @sgr << STYLES[method]
    elsif COLORS.key?(method)
      @sgr << COLORS[method] + COLOR_FG
    elsif method.to_s.start_with?("on_")
      color = method.to_s[3..-1].to_sym
      @sgr << COLORS[color] + COLOR_BG if COLORS.key?(color)
    end

    return self if args.empty?
    out = String.new
    out << CSI + @sgr.join(";") + SGR unless @sgr.empty?
    out << args.join
    out << CSI + STYLES[:reset].to_s + SGR unless @sgr.empty?
    @sgr.clear
    return out
  end
end

