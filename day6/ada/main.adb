with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Hashed_Maps;

procedure Main is
	-- Count the number of lines in a file
	function Count_Lines(Filename: String) return Natural is
		File: File_Type;
		Count: Natural := 0;
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			declare
				Line: String := Get_Line(File);
			begin
				Count := Count + 1;
			end;
		end loop;
		Close(File);
		return Count;
	end Count_Lines;

	-- Count the number of commas in a string
	function Count_Commas(Line: String) return Natural is
		Count: Natural := 0;
	begin
		for Char of Line loop
			if Char = ',' then
				Count := Count + 1;
			end if;
		end loop;
		return Count;
	end Count_Commas;

	-- Represent each ingredient as a four-digit number in base-26
	type Ingredient is new Natural range 0..26**4-1;
	type Ingredient_Array is array(Natural range <>) of Ingredient;
	
	-- Each Ingredient maps to a list of Ingredients which comprise it
	function Hash_Ingredient(Key: Ingredient) return Ada.Containers.Hash_Type is
	begin
		return Ada.Containers.Hash_Type(Key);
	end Hash_Ingredient;
	-- The map must be Indefinite becaues the array Element type is unconstrained
	-- ie the size is unknown at compile-time
	package Ingredient_Maps is new Ada.Containers.Indefinite_Hashed_Maps (
		Key_Type => Ingredient,
		Element_Type => Ingredient_Array,
		Hash => Hash_Ingredient,
		Equivalent_Keys => "="
	);
	subtype Ingredient_Map is Ingredient_Maps.Map;

	package Ingredient_Counts is new Ada.Containers.Hashed_Maps (
		Key_Type => Ingredient,
		Element_Type => Natural,
		Hash => Hash_Ingredient,
		Equivalent_Keys => "="
	);
	subtype Ingredient_Count is Ingredient_Counts.Map;

	function String_To_Ingredient(Line: String) return Ingredient is
		function Char_To_Ingredient(C: Character) return Ingredient is
		begin
			return Character'Pos(C) - Character'Pos('A');
		end Char_To_Ingredient;
	
		Result: Ingredient := 0;
	begin
		for Index in Line'First..Line'First+3 loop
			Result := 26*Result + Char_To_Ingredient(Line(Index));
		end loop;

		-- Make NULLv1,2,3 different
		if Line'Length > 5 and then Line(Line'First+4) = 'v' then
			Result := Result + Character'Pos(Line(Line'First+5));
		end if;
		return Result;
	end String_To_Ingredient;

	procedure Parse_Line(Map: in out Ingredient_Map; Line: String) is
		Num_Ingredients: constant Natural := Count_Commas(Line) + 1;
		Arr: Ingredient_Array(1..Num_Ingredients);
		Arr_Index: Natural := 1;
	begin
		for I in Line'Range loop
			if Line(I) in ':' | ',' then
				Arr(Arr_Index) := String_To_Ingredient(Line(I+1..Line'Last));
				Arr_Index := Arr_Index + 1;
			end if;
		end loop;
		Map.Insert(String_To_Ingredient(Line), Arr);
	end Parse_Line;

	function Parse_File(Filename: String) return Ingredient_Map is
		Map: Ingredient_Map;
		File: File_Type;
	begin
		Open(File, In_File, Filename);
		while not End_Of_File(File) loop
			declare
				Line: String := Get_Line(File);
			begin
				Parse_Line(Map, Line);
			end;
		end loop;
		Close(File);
		return Map;
	end Parse_File;

	procedure Count_Ingredients(
		Start: Ingredient;
		Map: in out Ingredient_Map;
		Count: in out Ingredient_Count)
	is
	begin
		-- Log each Ingredient type that's hit
		if not Count.Contains(Start) then
			Count.Insert(Start, 1);
		end if;
		
		if Map.Contains(Start) then
			declare
				Arr: Ingredient_Array := Map.Element(Start);
			begin
				-- In case there's a loop in the graph, delete the current entry we're processing
				Map.Delete(Start);
				for Element of Arr loop
					Count_Ingredients(Element, Map, Count);
				end loop;
			end;
		end if;
	end Count_Ingredients;

	function Part_One(Filename: String) return Natural is
		Result: Natural := 0;
		Map: Ingredient_Map := Parse_File(Filename);
		Count: Ingredient_Count;
		NULL_Ingredient: Ingredient := String_To_Ingredient("NULL");
	begin
		Count_Ingredients(NULL_Ingredient, Map, Count);
		return Natural(Count.Length)-1;
	end Part_One;

	function Part_Two(Filename: String) return Natural is
		Result: Natural := 0;
		Map: Ingredient_Map := Parse_File(Filename);
		NULL_Ingredient: Ingredient := String_To_Ingredient("NULL");
	begin
		for Recipe in Map.Iterate loop
			declare
				Map_Copy: Ingredient_Map := Map;
				Key: Ingredient := Ingredient_Maps.Key(Recipe);
				Count: Ingredient_Count;
			begin
				Count_Ingredients(Key, Map_Copy, Count);
				if Count.Contains(NULL_Ingredient) and Key /= NULL_Ingredient then
					Result := Result + 1;
				end if;
			end;
		end loop;
		return Result;
	end Part_Two;

	function Part_Three(Filename: String) return Natural is
		Result: Natural := 0;
		Map: Ingredient_Map := Parse_File(Filename);
		NULL_ONE: Ingredient := String_To_Ingredient("NULLv1");
		NULL_TWO: Ingredient := String_To_Ingredient("NULLv2");
		NULL_THREE: Ingredient := String_To_Ingredient("NULLv3");
	begin
		for Recipe in Map.Iterate loop
			declare
				Map_Copy: Ingredient_Map := Map;
				Key: Ingredient := Ingredient_Maps.Key(Recipe);
				Count: Ingredient_Count;
				Num_Nulls: Natural := 0;
			begin
				Count_Ingredients(Key, Map_Copy, Count);
				if Count.Contains(NULL_ONE) and Key /= NULL_ONE then
					Num_Nulls := Num_Nulls + 1;
				end if;
				if Count.Contains(NULL_TWO) and Key /= NULL_TWO then
					Num_Nulls := Num_Nulls + 1;
				end if;
				if Count.Contains(NULL_THREE) and Key /= NULL_THREE then
					Num_Nulls := Num_Nulls + 1;
				end if;
				if Num_Nulls > 1 then
					Result := Result + 1;
				end if;
			end;
		end loop;
		return Result;
	end Part_Three;

begin
	declare
		X: Natural := Part_One("test1.txt");
	begin
		pragma Assert(X = 7, "got" & X'Image);
	end;
	Put_Line("Part 1: " & Part_One("everybody_codes_e2026_q06_p1.txt")'Image);
	
	declare
		X: Natural := Part_Two("test2.txt");
	begin
		pragma Assert(X = 6, "got" & X'Image);
	end;
	Put_Line("Part 2: " & Part_Two("everybody_codes_e2026_q06_p2.txt")'Image);

	declare
		X: Natural := Part_Three("test3.txt");
	begin
		pragma Assert(X = 3, "got" & X'Image);
	end;
	Put_Line("Part 3: " & Part_Three("everybody_codes_e2026_q06_p3.txt")'Image);
end Main;
