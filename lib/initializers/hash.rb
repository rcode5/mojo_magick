class Hash
  def symbolize_keys!
    keys.each do |key|
      self[begin
        key.to_sym
      rescue StandardError
        key
      end || key] = delete(key)
    end
    self
  end
end
