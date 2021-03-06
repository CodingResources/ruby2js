require 'ruby2js'

module Ruby2JS
  module Filter
    module Wunderbar
      include SEXP

      def on_send(node)
        target, method, *attrs = node.children

        if target == s(:const, nil, :Wunderbar)
          if [:debug, :info, :warn, :error, :fatal].include? method
            method = :error if method == :fatal
            return node.updated(nil, [s(:const, nil, :console), method, *attrs])
          end
        end

        stack = []
        while target!=nil and target.type==:send and target.children.length==2
          name = method.to_s
          if name.end_with? '!'
            stack << s(:hash, s(:pair, s(:sym, :id), s(:str, name[0..-2])))
          else
            stack << s(:hash, s(:pair, s(:sym, :class), s(:str, name)))
          end
          target, method = target.children
        end

        if target == nil and method.to_s.start_with? "_"
          S(:xnode, *method.to_s[1..-1], *stack, *process_all(attrs))
        else
          super
        end
      end

      def on_block(node)
        send, args, *block = node.children
        target, method, *_ = send.children
        while target!=nil and target.type==:send and target.children.length==2
          target, method = target.children
        end

        if target == nil and method.to_s.start_with? "_"
          if args.children.empty?
            # append block as a standalone proc
            process send.updated(nil, [*send.children, *process_all(block)])
          else
            # iterate over Enumerable arguments if there are args present
            send = send.children
            return super if send.length < 3
            process s(:block, s(:send, *send[0..1], *send[3..-1]),
              s(:args), s(:block, s(:send, send[2], :map),
              *node.children[1..-1]))
          end
        else
          super
        end
      end
    end

    DEFAULTS.push Wunderbar
  end
end
