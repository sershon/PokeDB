-- Q0: the name of the database on the class server in which I can find your schema
--     parkb23 contains the schema.

-- Q1: a list of CREATE TABLE statements implementing your schema

-- Contains a list of all players who have registered for a division.
CREATE TABLE Players (
    "player_id" VARCHAR(100),
    "age" INT,
    "division" VARCHAR(20)
    CONSTRAINT PK_players Primary Key (player_id)
);

-- Contains the registered teams under each player.
CREATE TABLE Pokemon_Team (
    "player_id" VARCHAR(100),
    "team_id" INT
    CONSTRAINT PK_pokemon_team Primary Key (team_id)
    CONSTRAINT FK_players FOREIGN KEY (player_id) REFERENCES Players
);

-- Contains the teams of registered pokemon.
CREATE TABLE Pokemon (
    "team_id" INT,
    "pokemon_name" VARCHAR(50),
    "pokemon#" VARCHAR(4),
    "ability" VARCHAR(30),
    "held_item" VARCHAR(50),
    "type" VARCHAR(15),
    "second_type" VARCHAR(15)
    CONSTRAINT PK_pokemon Primary Key (team_id, pokemon_name)
    CONSTRAINT FK_pokemon FOREIGN KEY (team_id) REFERENCES Pokemon_Team
);

-- Would contain a table of all moves available to use legally.
CREATE TABLE Moves (
    "move_name" VARCHAR(50),
    "power" INT,
    "move_type" VARCHAR(20),
    "damage_type" VARCHAR(10),
    "pp" INT
    CONSTRAINT PK_moves Primary Key (move_name)
);

-- Records the moves owned by each pokemon on a team.
CREATE TABLE Movesets (
    "team_id" INT,
    "pokemon_name" VARCHAR(50),
    "move_1" VARCHAR(50),
    "move_2" VARCHAR(50),
    "move_3" VARCHAR(50),
    "move_4" VARCHAR(50)
    CONSTRAINT PK_moveset PRIMARY KEY (team_id, pokemon_name)
    CONSTRAINT FK_moveset1 FOREIGN KEY (team_id, pokemon_name) REFERENCES Pokemon,
    CONSTRAINT FK_moveset2 FOREIGN KEY (move_1) REFERENCES Moves,
    CONSTRAINT FK_moveset3 FOREIGN KEY (move_2) REFERENCES Moves,
    CONSTRAINT FK_moveset4 FOREIGN KEY (move_3) REFERENCES Moves,
    CONSTRAINT FK_moveset5 FOREIGN KEY (move_4) REFERENCES Moves
)

-- Contains all the tournaments and dates of their completion.
CREATE TABLE Tournaments (
    "tournament_name" VARCHAR(40),
    "tournament_date" DATETIME,
    "tournament_id" INT
    CONSTRAINT PK_tournaments PRIMARY KEY (tournament_id)
)

-- Records each battle between 2 players and its result.
CREATE TABLE Battles (
    "tournament_id" INT,
    "battle_id" INT,
    "player_1_team_id" INT,
    "player_2_team_id" INT,
    "winner_team_id" INT
    CONSTRAINT PK_battles PRIMARY KEY (tournament_id, battle_id)
    CONSTRAINT FK_battles1 FOREIGN KEY (tournament_id) REFERENCES Tournaments,
    CONSTRAINT FK_battles3 FOREIGN KEY (player_1_team_id) REFERENCES Pokemon_Team,
    CONSTRAINT FK_battles5 FOREIGN KEY (player_2_team_id) REFERENCES Pokemon_Team,
    CONSTRAINT FK_battles6 FOREIGN KEY (winner_team_id) REFERENCES Pokemon_team
)



-- Q2: a list of 10 SQL statements using your schema, along with the English question it implements.

--J1: What was the team of Pokemon with the highest number of wins(and how many was it)? (Tournament organizers) 
SELECT TOP 1 b.winner_team_id as 'Team with most wins', COUNT(b.winner_team_id) as Total
FROM Battles as b
GROUP BY b.winner_team_id
ORDER BY Total DESC
;

--J2: What held item is the most popular across all teams(and how many times was it used)? (Players)
SELECT TOP 1 P.held_item, COUNT(P.held_item) AS Total
FROM Pokemon as P
GROUP BY P.held_item
ORDER BY Total DESC
;

--J3: Which move is the most popular across any Pokemon among all teams(and how many times was it used)? (Players / Developers) 
WITH overall_moves as (
    SELECT move_1 FROM Movesets
    UNION ALL
    SELECT move_2 FROM Movesets
    UNION ALL
    SELECT move_3 FROM Movesets
    UNION ALL
    SELECT move_4 FROM Movesets
)
SELECT TOP 1 O.move_1 as Move, COUNT(O.move_1) AS Total
FROM overall_moves as O
GROUP BY O.move_1
ORDER BY Total DESC 
;

--J4: What combination of two Pokemon was the most popular across all Pokemon teams(and how many times were they used)? (Players)
With temp AS (
    SELECT P.team_id, P.pokemon_name
    FROM Pokemon as P
    GROUP BY P.team_id, pokemon_name
)
SELECT TOP 1 pokemon_1, pokemon_2, COUNT(*) AS times_used
FROM (
    SELECT
    u1.pokemon_name AS pokemon_1,
    u2.pokemon_name AS pokemon_2
    FROM temp u1
    JOIN temp u2
    ON u1.pokemon_name < u2.pokemon_name AND u1.team_id = u2.team_id
) sub
GROUP BY pokemon_1, pokemon_2 ORDER BY times_used DESC
;

--J5: What Pokemon type was the most popular(and how many times was it used)? (Players, tournament organizers, developers)
WITH types as (
    SELECT "type" FROM Pokemon
    UNION ALL
    SELECT "second_type" FROM Pokemon
)
SELECT TOP 1 t.type as Type, COUNT(t.type) AS Total
FROM types as t
GROUP BY t.type
ORDER BY Total DESC
;

--J6: Which ability appeared the most amongst all Pokemon and all Pokemon teams(and how many times was it used)? (Players / developers)
SELECT TOP 1 P.ability, COUNT(P.ability) AS Total
FROM Pokemon as P
GROUP BY P.ability
ORDER BY Total DESC
;

--B2: What player has won the most tournaments(and how many times)? (Players/Analysts)
WITH Winners as(
    SELECT B.tournament_id, P.player_id, B.winner_team_id, COUNT(*) as Wins
    FROM Battles as B JOIN Pokemon_Team as P
    ON B.winner_team_id = P.team_id
    GROUP BY tournament_id, winner_team_id, player_id
),
WinnersList as (
    SELECT W.player_id, W.tournament_id
    FROM Winners as W
    INNER JOIN (
        SELECT W2.tournament_id, MAX(W2.Wins) as MaxWins
        FROM Winners as W2
        GROUP BY W2.tournament_id
    ) as W3 ON W.tournament_id = W3.tournament_id and W.Wins = W3.MaxWins
)
SELECT TOP 1 WinnersList.player_id, COUNT(*) as #ofWins
FROM WinnersList
GROUP BY WinnersList.player_id
ORDER BY #ofWins DESC
;

--B3 What is Brynne_Frost_2’s most used pokemon? (Players/Analysts)
SELECT TOP 1 p.player_id, poke.pokemon_name, COUNT(*) AS 'Times Used'
FROM Pokemon poke 
INNER JOIN Pokemon_Team p ON poke.team_id = p.team_id
WHERE player_id = 'Brynne_Frost_2'
GROUP BY p.player_id, poke.pokemon_name
ORDER BY 'Times Used' DESC
;

--B6: Which players used the same team at more than 1 tournament? (Players/Analysts)
WITH Players as(
    SELECT tournament_id, tbl.player_1_team_id as team_id FROM (
        SELECT player_1_team_id, tournament_id FROM Battles
        UNION
        SELECT player_2_team_id, tournament_id FROM Battles
    ) as tbl
)
SELECT Pokemon_Team.player_id as 'Player ID'
FROM Pokemon_Team, (
    SELECT Players.team_id, COUNT(*) as '# of uses'
    FROM Players
    GROUP BY Players.team_id
    HAVING COUNT(*) > 1
) as W
WHERE Pokemon_Team.team_id = W.team_id
ORDER BY [Player ID] ASC
;

--R6: On average, how many battles were fought in tournaments in each year? (Analysts)
WITH TournamentBattles AS (
    SELECT COUNT(battle_id) AS battlesums, b.tournament_id
    FROM Battles b
    GROUP BY tournament_id
)
SELECT AVG(battlesums) AS average_battles, YEAR(t.tournament_date) AS year
FROM Tournaments AS t
JOIN TournamentBattles tb ON t.tournament_id = tb.tournament_id
GROUP BY YEAR(t.tournament_date)
;


-- Q3: a list of 3-5 demo queries that return (minimal) sensible results.  These can be a subset of the 10 queries implemented for Q2, in which case it's ok to list them twice.

--J1: What was the team of Pokemon with the highest number of wins(and how many was it)? (Tournament organizers) 
SELECT TOP 1 b.winner_team_id as 'Team with most wins', COUNT(b.winner_team_id) as Total
FROM Battles as b
GROUP BY b.winner_team_id
ORDER BY Total DESC
;

--J4: What combination of two Pokemon was the most popular across all Pokemon teams(and how many times were they used)? (Players)
With temp AS (
    SELECT P.team_id, P.pokemon_name
    FROM Pokemon as P
    GROUP BY P.team_id, pokemon_name
)
SELECT TOP 1 pokemon_1, pokemon_2, COUNT(*) AS times_used
FROM (
    SELECT
    u1.pokemon_name AS pokemon_1,
    u2.pokemon_name AS pokemon_2
    FROM temp u1
    JOIN temp u2
    ON u1.pokemon_name < u2.pokemon_name AND u1.team_id = u2.team_id
) sub
GROUP BY pokemon_1, pokemon_2 ORDER BY times_used DESC
;

--B6: Which players used the same team at more than 1 tournament? (Players/Analysts)
WITH Players as(
    SELECT tournament_id, tbl.player_1_team_id as team_id FROM (
        SELECT player_1_team_id, tournament_id FROM Battles
        UNION
        SELECT player_2_team_id, tournament_id FROM Battles
    ) as tbl
)
SELECT Pokemon_Team.player_id as 'Player ID'
FROM Pokemon_Team, (
    SELECT Players.team_id, COUNT(*) as '# of uses'
    FROM Players
    GROUP BY Players.team_id
    HAVING COUNT(*) > 1
) as W
WHERE Pokemon_Team.team_id = W.team_id
ORDER BY [Player ID] ASC
;

--Bonus Which 3 teams had the best win rates(what were they)?
WITH Matches as (
  SELECT player_1_team_id, COUNT(*) as matchcount FROM (
    SELECT player_1_team_id FROM Battles
    UNION ALL
    SELECT player_2_team_id FROM Battles
  ) tbl
  GROUP BY tbl.player_1_team_id
)
SELECT TOP 3 B.winner_team_id as team_id, 
    CAST(COUNT(B.winner_team_id) as float) / CAST(Matches.matchcount as float) * 100 as win_percent
FROM Battles as B
JOIN Matches
on Matches.player_1_team_id = B.winner_team_id
GROUP BY B.winner_team_id, Matches.matchcount
ORDER BY win_percent DESC
;