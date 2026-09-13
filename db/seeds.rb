Player.destroy_all

players = [
  {
    name: "Erling Haaland",
    date_of_birth: Date.new(2000, 7, 21),
    height: 195,
    nationality: "Norway",
    position: "FW",
    preferred_foot: "Left",
    club: "Manchester City"
  },
  {
    name: "Kevin De Bruyne",
    date_of_birth: Date.new(1991, 6, 28),
    height: 181,
    nationality: "Belgium",
    position: "MF",
    preferred_foot: "Right",
    club: "Manchester City"
  },
  {
    name: "Bukayo Saka",
    date_of_birth: Date.new(2001, 9, 5),
    height: 178,
    nationality: "England",
    position: "FW",
    preferred_foot: "Left",
    club: "Arsenal"
  },
  {
    name: "Martin Ødegaard",
    date_of_birth: Date.new(1998, 12, 17),
    height: 178,
    nationality: "Norway",
    position: "MF",
    preferred_foot: "Left",
    club: "Arsenal"
  },
  {
    name: "Mohamed Salah",
    date_of_birth: Date.new(1992, 6, 15),
    height: 175,
    nationality: "Egypt",
    position: "FW",
    preferred_foot: "Left",
    club: "Liverpool"
  },
  {
    name: "Son Heung-min",
    date_of_birth: Date.new(1992, 7, 8),
    height: 183,
    nationality: "South Korea",
    position: "FW",
    preferred_foot: "Both",
    club: "Tottenham Hotspur"
  }
]

players.each do |player_data|
  Player.create!(player_data)
end

puts "Seeded #{Player.count} players."
