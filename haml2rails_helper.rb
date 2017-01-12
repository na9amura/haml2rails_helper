def convert(line)
  case line
  when /\A\=/ then line
  when /%img/ then convert_img_tag(line)
  when /%a/   then convert_a_tag(line)
  else line
  end
end

def convert_img_tag(line)
  tag = '%img'
  classes = strip_to_classes(line, tag)
  matchers = [/#{ tag }/]
  matchers << /#{ Regexp.escape(classes) }/   unless classes.empty?
  options = extract_options(line, *matchers)

  ''.tap do |text|
    text << "= image_tag '#{ options[:src] }'"
    text << ", size: '#{ options[:width] }x#{ options[:height] }'"
    text << ", class: '#{ classes.gsub(/\./, ' ') }'"  unless classes.empty?
    text << ", alt: '#{ options[:alt] }'" if options.key?(:alt) && !options[:alt].empty?
  end
end

def convert_a_tag(line)
  tag = '%a'
  classes = strip_to_classes(line, tag)

  matchers = [/#{ tag }/]
  matchers << /#{ Regexp.escape(classes) }/ unless classes.empty?
  link_item = gsub_to_empty(line, /{.*}/, *matchers)

  matchers << /#{ Regexp.escape(link_item) }/ unless link_item.empty?
  options = extract_options(line, *matchers)

  ''.tap do |text|
    if link_item.empty?
      text << "= link_to '#{ options[:href] }' do"
    else
      text << "= link_to '#{ gsub_to_empty(link_item, /> /).strip }', '#{ options[:href] }'"
    end
    text << ", class: '#{ classes.gsub(/\./, ' ') }'"  unless classes.empty?
  end
end

def strip_to_classes(line, tag)
  line.scan(/#{ tag }(.*){/)&.first&.first || ''
end

def extract_options(line, *matchers)
  attrs = gsub_to_empty(line, *matchers)
  eval(attrs.to_s)
end

def gsub_to_empty(base, *matchers)
  matchers.inject(base) { |a, e| a = a.gsub(e, '') }
end

if ARGV.length != 2
  puts 'arguments error'
  exit
end
input_path = ARGV[0]
output_path = ARGV[1]

File.open(output_path, 'w') do |output|
  File.open(input_path) do |input|
    input.each_line do |_line|
      tabs = _line.scan('  ').count
      line = _line.strip.gsub(/\/$/, '')
      converted = "#{ '  ' * tabs }#{ convert(line) }\n"
      output.puts converted
    end
  end
end
