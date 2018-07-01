defmodule BenchmarkParsing do
	import NimbleParsec

	whitespace =
		utf8_string([?\s, ?\t], min: 1)
		|> replace(:whitespace)

	date =
		integer(4)
		|> ignore(string("-"))
		|> integer(2)
		|> ignore(string("-"))
		|> integer(2)
		|> wrap

	quoted_symbol =
		ignore(string("\""))
		|> utf8_string([{:not, ?"}, {:not, ?\r}, {:not, ?\n}], min: 1)
		|> ignore(string("\""))
		|> unwrap_and_tag(:quoted)

	unquoted_symbol =
		utf8_string([{:not, ?-}, {:not, ?0..?9}, {:not, ?\s}, {:not, ?"}, {:not, ?\t}, {:not, ?\r}, {:not, ?\n}], min: 1)
		|> unwrap_and_tag(:unquoted)

	symbol = choice([quoted_symbol, unquoted_symbol])

	quantity =
		optional(utf8_char([?-]))
		|> utf8_string([?0..?9, ?,, ?.], min: 1)

	amount_symbol_then_quantity =
		symbol
		|> optional(whitespace)
		|> concat(quantity)
		|> wrap

	amount_quantity_then_symbol =
		quantity
		|> optional(whitespace)
		|> concat(symbol)
		|> wrap

	amount =
		choice([amount_symbol_then_quantity, amount_quantity_then_symbol])

	price =
		ignore(utf8_char([?P]))
		|> ignore(whitespace)
		|> concat(date)
		|> ignore(whitespace)
		|> concat(symbol)
		|> ignore(whitespace)
		|> concat(amount)

	price_line =
		price
		|> ignore(choice([utf8_char([?\n]), utf8_string([?\r, ?\n], 2)]))
		|> wrap

	defparsec :price_db, repeat(price_line)

	def load_pricedb() do
		file = File.open!("/Users/mark/Nexus/Documents/finances/ledger/.pricedb", [:utf8, :read])
		lines = IO.read(file, :all)
		File.close(file)
		{:ok, prices, _, _, _, _} = price_db(lines)
		prices
	end

	def main(_args) do
		prices = load_pricedb()
		IO.puts "#{Enum.count prices} total prices"
	end

end
