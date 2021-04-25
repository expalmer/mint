module Mint
  class Cli < Admiral::Command
    class Lint < Admiral::Command
      include Command

      define_help description: "Lints the project for syntax and type errors."

      define_flag json : Bool,
        description: "Output errors to a JSON file",
        default: false,
        required: false

      def run
        execute "Linting" do
          lint
        end
      end

      def lint
        sources = [] of String
        errors = [] of Exception

        ast =
          Ast.new
            .merge(Core.ast)

        begin
          sources =
            Dir.glob(SourceFiles.all)
        rescue ex
          ex_handler errors, ex
        end

        sources.reduce(ast) do |memo, file|
          parsed = Parser.parse(file)

          if memo
            memo.merge parsed
          end
        rescue ex
          ex_handler errors, ex
        end

        if errors.empty?
          type_checker =
            TypeChecker.new(ast)

          done = false

          while !done
            begin
              type_checker.check
            rescue ex
              ex_handler errors, ex
            else
              done = true
            end
          end
        end

        if flags.json
          puts errors.compact_map(&.message.presence).to_json
        end

        if errors.size > 0
          exit 1
        end
      end

      def ex_handler(errors, ex)
        errors << ex

        puts ex
      end
    end
  end
end
