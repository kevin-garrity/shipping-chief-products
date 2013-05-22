class Hash
  def expand

    rows = values.map{|v| v.is_a?(Array) ? v.length : 1}
    rows = rows.max
    result = Array.new(rows)
    0.upto(rows - 1) do |ix|
      result [ix] = Hash[map{|k,v|  [k, v.is_a?(Array) ? (v[ix] ? v[ix].duperself : nil) : v.duperself]}]
    end
    result
  end
end

class Object
  def duperself
    return self if self.is_a?(Numeric)
    begin dup rescue self end
  end
end