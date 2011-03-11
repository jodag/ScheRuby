require 'singleton'

module ScheRuby
  
  class EmptyList
    include Singleton
    
    # According to R5RS, car and cdr of the EmptyList result in errors
    # (as opposed to other Lisp dialects where they return the EmptyList itself)
    
    # Note that #null? is different from Ruby's #nil?
    def null?
      true
    end
    
    def atom?
      true
    end
    
    def pair?
      false
    end
    
    def list?
      true
    end

    def listmap(fn)
      # (define (map fn lst) (if (null? lst) lst (cons (fn (car lst) (map fn (cdr lst))))))
      # Note that this shold eventuallty be turned iterative for performance
      self
    end
        
    def inspect
      '()'
    end
    
    include Enumerable
    def each
      # empty list, so nothing to yield
    end
    
  end
  
  class Cons
    attr_accessor :car, :cdr
    
    EMPTY_LIST = EmptyList.instance
    
    def initialize(_car, _cdr)
      @car = _car
      @cdr = _cdr
    end
    
    def self.cons(_car, _cdr)
      new(_car, _cdr)
    end
    
    def self.list(*args)
      lst = EMPTY_LIST
      for arg in args.reverse
        lst = Cons.cons(arg, lst)
      end
      return lst
    end
    
    # Only works if is proper list
    def to_a
      raise ArgumentError, "#{self.inspect} is not a list" unless list?
      a = [car] + (cdr.null? ? [] : cdr.to_a)
    end
    
    # Returns a list of +lst+ with +element+ adjoined.  
    # To avoid consing, +lst+ MAY be modified in place (this is not guaranteed).
    def self.adjoin!(lst, element)
      raise ArgumentError, "#{lst.inspect} is not a list or the empty list" unless lst.null? || lst.list?
      return list(element) if lst.null?
      last_pair = lst
      while ! (last_pair.cdr.null?)
        last_pair = last_pair.cdr
      end
      last_pair.cdr = Cons.cons(element, EMPTY_LIST)
      return lst
    end
    
    def self.append(list1, list2)
      list1.null? ? list2 : cons(list1.car, append(list1.cdr, list2))
    end
    
    def pair?
      true
    end
    
    def list?
      cdr.list?
    end
    
    def atom?
      false
    end
    
    def inspect
      if list?
        insp = '('
        current = self
        while ! current.cdr.null?
          insp += current.car.inspect
          insp += ' '
          current = current.cdr
        end
        insp += current.car.inspect
        insp += ')'
        return insp
      else
        "(#{@car.inspect} . #{@cdr.inspect})"
      end
    end
       
    def listmap(fn)
      # (define (map fn lst) (if (null? lst) lst (cons (fn (car lst) (map fn (cdr lst))))))
      # Note that this should eventuallty be turned iterative for performance
      raise ArgumentError, "{#self.inspect} is not a list" unless list?
      acc = EMPTY_LIST
      current = self
      while ! current.cdr.null?
        acc = Cons.adjoin!(acc, fn.call(current.car))
        current = current.cdr
      end
      Cons.adjoin!(acc, fn.call(current.car))
    end
    
    # To circumvent an RDoc bug, we need to set these vars instead of inline in the alias_method call
    setcar = 'set-car!'.to_sym
    alias_method setcar, :car=
    setcdr = 'set-cdr!'.to_sym
    alias_method setcdr, :cdr=    
    
    include Enumerable
    def each
      raise ArgumentError, "{#self.inspect} is not a list" unless list?
      current = self
      while ! current.cdr.null?
        yield current.car
        current = current.cdr
      end
      yield current.car
    end 
  
  end
  
  
end

class Object
  def eval!(binding = Kernel,env_frame = EnvFrame.new)
    self
  end
  
  # These methods are overriden by Cons
  def list?
    false
  end
  
  # These methods are overriden by Cons
  def pair?
    false
  end
  
  # Note that Ruby's +nil+ is considered an atom and NOT null
  def atom?
    true
  end
  
  # Note that Ruby's +nil+ is considered an atom and NOT null
  def null?
    false
  end
end