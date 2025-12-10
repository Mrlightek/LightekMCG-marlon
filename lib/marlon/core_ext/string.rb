class String
  def blank?
    self.strip.empty?
  end

  def present?
    !blank?
  end
end
