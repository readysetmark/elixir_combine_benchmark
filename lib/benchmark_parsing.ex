defmodule BenchmarkParsing do
	import Combine.Parsers.Base
	import Combine.Parsers.Text

	def mandatory_whitespace() do
		many1(either(tab, space))
		|> map(fn _ -> :whitespace end)
	end

	def whitespace() do
		many(either(tab, space))
		|> map(
			fn list ->
				case list do
					_ when length(list) > 0 -> :whitespace
					_												-> :no_whitespace
				end
			end)
	end


	def year() do
		fixed_integer(4)
	end

	def month() do
		fixed_integer(2)
	end

	def day() do
		fixed_integer(2)
	end

	def date() do
		sequence([
			year(),
			ignore(char("-")),
			month(),
			ignore(char("-")),
			day()
		])
		|> map(fn [year, month, day] -> {year, month, day} end)
	end


	def quoted_symbol() do
		sequence([
			ignore(char("\"")),
			many1(satisfy(char, fn c -> !(c in String.codepoints("\"\r\n")) end)),
			ignore(char("\""))
		])
		|> map(fn list -> {:quoted, Enum.join(list)} end)
	end

	def unquoted_symbol() do
		many1(satisfy(char, fn c -> !(c in String.codepoints("-0123456789; \"\t\r\n")) end))
		|> map(fn list -> {:unquoted, Enum.join(list)} end)
	end

	def symbol() do
		either(quoted_symbol, unquoted_symbol)
	end


	def digit_char() do
		satisfy(char, fn c -> c in String.codepoints("0123456789") end)
	end

	def quantity() do
		sequence([
			option(char("-"))
			|> map(fn "-" -> "-"
								_ -> "" end),
			digit_char(),
			many(choice([digit_char(), char(","), char(".")]))
		])
		|> map(fn list -> 
			list
			|> List.flatten
			|> Enum.join
			|> String.replace(",", "")
		end)
	end


	def amount_symbol_then_quantity() do
		sequence([
			symbol(),
			whitespace(),
			quantity()
		])
		|> map(fn [symbol, ws, qty] ->
			case ws do
				:whitespace -> {qty, symbol, :symbol_left_with_space}
				:no_whitespace -> {qty, symbol, :symbol_left_no_space}
			end
		end)
	end

	def amount_quantity_then_symbol() do
		sequence([
			quantity(),
			whitespace(),
			symbol()
		])
		|> map(fn [qty, ws, symbol] ->
			case ws do
				:whitespace -> {qty, symbol, :symbol_right_with_space}
				:no_whitespace -> {qty, symbol, :symbol_right_no_space}
			end
		end)
	end

	def amount() do
		either(amount_symbol_then_quantity, amount_quantity_then_symbol)
	end


	def price() do
		# P 2007-08-15 "AIM1651" $5.82
		sequence([
			ignore(char("P")),
			ignore(mandatory_whitespace()),
			date(),
			ignore(mandatory_whitespace()),
			symbol(),
			ignore(mandatory_whitespace()),
			amount()
		])
		|> map(fn [date, symbol, amount] -> {date, symbol, amount} end)
	end

	def price_db() do
		sep_by(price, newline)
	end

	def load_pricedb() do
		[prices] = Combine.parse_file("/Users/mark/Nexus/Documents/finances/ledger/.pricedb", price_db)
		prices
	end

	def main(args) do
		prices = load_pricedb()
		IO.puts "#{Enum.count prices} total prices"
	end

end
