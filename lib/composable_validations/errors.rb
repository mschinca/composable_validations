class ComposableValidations::Errors
  def initialize(errors, message_map = nil)
    @errors = errors
    @message_map = DEFAULT_MESSAGE_MAP.merge(message_map || {})
  end

  def add(msg, path, object)
    merge(@errors, {join(path) => [render_message(msg, path, object)]})
  end

  def to_hash
    @errors
  end

  private

  def render_message(msg, path, object)
    message = Array(msg)
    message_builder = @message_map.fetch(message.first, msg)
    if message_builder.is_a?(Proc)
      message_builder.call(object, path, *msg[1..-1])
    else
      message_builder
    end
  end

  def merge(e1, e2)
    e2.keys.each do |k, v|
      e1[k] = ((e1[k] || []) + (e2[k] || [])).uniq
    end
  end

  def join(segments)
    if segments.empty?
      segments[0] = base_key
    end

    segments.compact.join(separator)
  end

  def base_key
    'base'
  end

  def separator
    '/'
  end
end
