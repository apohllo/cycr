class String
  def to_cyc(quote = false)
    #self =~ /_missing_method_(.*)/ ? "#{$1.gsub("_","-")}" : "\"#{self}\""
    "\"#{self}\""
  end
end

class Symbol
  def to_cyc(quote = false)
    (quote ? "'" : "") + "#\$#{self}"
  end
end

class Array
  def to_cyc(quote = false)
    (quote ? "'" : "") + 
      "("+map{|e| e.to_cyc(quote)}.join(" ")+")"
  end
end

class Fixnum
  def to_cyc(quote = false)
    to_s
  end
end

