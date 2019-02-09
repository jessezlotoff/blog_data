##########
# build and solve sudoku puzzles
# Jesse Zlotoff
# 2/5/19
##########

import pandas as pd
import math
import random
import copy
import json
import pdb

##########


##########
class sudoku():
    

    ##########
    @staticmethod
    def validate(value, type):
        '''check if the input value is valid for the given type

        Positional arguments:
            value -- value to test
            type -- string ('value', 'index')
                valid 'value': integers 1-9
                valid 'index': integers 0-8
        
        Returns True/False validation, the value
        '''
        ### check type
        try:
            if str(type).lower().strip() not in ['value', 'index']:
                raise ValueError('invalid type, use \'value\', \'index\'')
                return (False, None)
        except:
            raise TypeError('type should be a string')
            return (False, None)

        ### check value for type='value'
        if type == 'value':
            try:
                value = int(value)
                if value in xrange(1, 10):
                    return (True, value)
                else:
                    return (False, None)
            except:
                raise TypeError('value should be an integer')
                return (False, None)

        ### check index for type='index'
        if type == 'index':
            try:
                value = int(value)
                if int(value) in xrange(0, 9):
                    return (True, value)
                else:
                    return  (False, None)
            except:
                raise TypeError('index should be an integer')
                return (False, None)


    ##########
    @staticmethod
    def convert_row_box(row, column, to='box'):
        '''convert row, column index from main data frame to box 
            data frame or back

        Positional arguments:
            row -- integer row number 0-8
            column -- integer column number 0-8

        Keyword arguments:
            to -- string type ('row', 'box')
        
        Returns new row, column index
        '''

        ### check inputs
        rv, row = sudoku.validate(row, 'index')
        cv, column = sudoku.validate(column, 'index')
        if not rv and cv:
            print 'invliad row or column'
            return None, None

        ### to 'box'
        if to == 'box':
            new_row = int(math.floor(column/3.0)) + int(math.floor(row/3.0)) * 3
            new_col = column % 3 + (row % 3) * 3
        elif to == 'row':
            new_row = int(math.floor(column/3.0)) + int(math.floor(row/3.0)) * 3
            new_col = column % 3 + (row % 3) * 3

        return new_row, new_col


    ##########
    @staticmethod
    def check_item(item, allow_empty=False):
        '''check that a row, column, box is correctly filled out

        Positional arguments:
            item -- dataframe series representing a row, column or box

        Keyword arguments:
            allow_empty -- boolean flag to accept empty squares

        Returns: True/False
        '''
        
        if not allow_empty:
            return sorted(item) == range(1,10)
        else:
            counts = item.value_counts()
            if not set(counts.index) <= set(range(0,10)):
                # value out of range
                return False
            elif {1} != set(counts[counts.index!=0].values):
                # duplicates found
                return False
            else:
                return True


    ##########
    @staticmethod
    def to_json_string(**kwargs):
        '''convert data to a dictionary and return json string

        Positional arguments:
        **kwargs -- list of name and value pairs
            should be key and value, usually a list
        
        Returns json as string
        '''

        d = {}
        for k in kwargs:
            d[k] = kwargs[k]
        return json.dumps(d)


    ##########
    def __init__(self):
        '''create sudoku instance
        
        Contents:
            .data is a pandas dataframe representing the sudoku grid
            .boxes is a pandas dataframe with each row representing a box
                in the .data dataframe
        
        Returns: sudoku instance
        '''
        index = range(0,9)
        columns = index
        row_col = pd.DataFrame(index=index,columns=columns)
        row_col = row_col.fillna(0)
        self.data = row_col
        self.boxes = row_col.copy()


    ##########
    def __repr__(self):
        '''object/instance representation of the grid
        '''
        
        return 'Sudoku:\n.data=\n' + str(self.data)


    ##########
    def __str__(self):
        '''string representation of the grid
        '''
        
        output = ''
        lines = '-' * 25
        output += lines + '\n'
        for r in xrange(0,9):
            row = list(self.data.loc[r])
            row = [str(x) + ' ' if x else '  ' for x in row]
            temp = '| ' + ''.join(row[0:3]) + '| '
            temp += ''.join(row[3:6]) + '| '
            temp += ''.join(row[6:9]) + '| '
            output += temp + '\n'
            if (r + 1) % 3 == 0:
                output += lines + '\n'
        output = output.rstrip()
        return output


    ##########
    def fill_square(self, row, column, value, type='row'):
        '''fill in a particular square in the grid,
        from the rows/columns or boxes grid, and update
        the other grid accordingly

        Positional arguments:
            row -- integer row number 0-8
            column -- integer column number 0-8
            value -- integer value to put in square 1-9

        Keyword arguments:
            type -- string type of grid ('row', 'box')
                'row' refers to the row/column grid or DataFrame
                'box' refers to the boxes grid or DataFrame
        
        Returns: None
        '''
        
        if type == 'row':
            self.data.iloc[row, column] = value
            nr, nc = sudoku.convert_row_box(row, column, to='box')
            self.boxes.iloc[nr, nc] = value
        elif type == 'box':
            self.boxes.iloc[row, column] = value
            nr, nc = sudoku.convert_row_box(row, column, to='row')
            self.data.iloc[nr, nc] = value


    ##########
    def blank(self):
        ''' remove all data from a sudoku instance

        Returns: None
        '''

        for r in range(0, 9):
            for c in range(0, 9):
                sudoku.fill_square(self, r, c, 0, type='row')


    ##########
    def fill_list(self, numbers):
        '''fill in the grid from a list of numbers
            that go across the top row and then down

        Positional arguments:
            numbers -- list of 81 integer values to fill in grid

        Returns: None
        '''
        r, c = 0, 0
        for n in numbers:
            sudoku.fill_square(self, r, c, n)
            c += 1
            if c == 9:
                c = 0
                r += 1


    ##########
    def find_errors(self, allow_empty=False):
        '''find errors in a grid

        Keyword arguments:
            allow_empty -- True/False to allow empty squares

        Returns: number of errors, list of string errors
        '''

        count = 0
        errors = []
        for r in xrange(0,9):
            if not sudoku.check_item(self.data.iloc[r], allow_empty=allow_empty):
                count += 1
                errors.append('row %s: %s' %(r+1, self.data.iloc[r].values))
        for c in xrange(0,9):
            if not sudoku.check_item(self.data[c], allow_empty=allow_empty):
                count += 1
                errors.append('column %s: %s' %(c+1, self.data[c].values))
        for b in xrange(0,9):
            if not sudoku.check_item(self.boxes.iloc[b], allow_empty=allow_empty):
                count += 1
                errors.append('box %s: %s' %(b+1, self.boxes.iloc[b].values))

        return count, errors


    ##########
    def solved(self):
        ''' determine if a grid is correctly solved

        Returns: True/False
        '''
        
        err = sudoku.find_errors(self, allow_empty=False)
        if err[0] == 0:
            return True
        else:
            return False


    ##########
    @staticmethod
    def available_values(item):
        '''find the remaining numbers that can be added to a row, column or box

        Returns: list of integers
        '''
        
        pool = set(range(1,10)) - set(item)
        return list(pool)


    ##########
    def available_values_square(self, row, column):
        '''find the remaining numbers that can be added to a given square

        Positional arguments:
            row -- integer row number 0-8
            column -- integer column number 0-8

        Returns: list of integers
        '''
        
        r_pool = sudoku.available_values(self.data.iloc[row])
        c_pool = sudoku.available_values(self.data[column])
        br, bc = sudoku.convert_row_box(row, column, to='box')
        b_pool = sudoku.available_values(self.boxes.iloc[br])
        comb = list(set(r_pool) & set(c_pool) & set(b_pool))
        return comb


    ##########
    def build_pool_dict(self, raw=False):
        ''' create a dictionary with a list of available values for each square
         in the grid

        Keyword arguments:
            raw -- boolean flag to use all numbers 1-9 for blank squares
                otherwise uses only valid values (default False)

        Returns: dictionary with (row, column) tuples as keys,
            list of values for each
        '''

        pool_dict = {}

        for r in range(0,9):
            for c in range(0,9):
                if not self.data.loc[r,c]:
                    # blank square
                    if raw:
                        pool_dict[(r, c)] = range(1,10)
                    else:
                        pool_dict[(r, c)] = sudoku.available_values_square(self, r, c)

        return pool_dict


    ##########
    @staticmethod
    def step(row, column, forward=True, type='row'):
        ''' find the 'next' square in the grid

        Positional arguments:
            row -- integer row number 0-8
            column -- integer column number 0-8

        Keyword arguments:
            forward -- True/False to step forward, otherwise backwards
                (deafult True)
            type -- string type of sequence ('row', 'column', 'box')
                (default 'row')
                'row' -- across each row, starting at the top
                'column' -- down each column, starting on the left
                'box' -- through each box, starting at the top left

        Returns: (row, column) tuple
                returns (-1, -1) if it steps too far in either direction
        '''

        # check type input
        if type.lower().strip() not in ('row', 'column', 'box'):
            print 'invalid type %s, use (\'row\', \'column\', \'box\')' %(type)
            return

        # determine step by type
        type = type.lower().strip()
        if type == 'row':
            if forward:
                if column == 8:
                    new_row = row + 1
                    new_col = 0
                else:
                    new_row = row
                    new_col = column + 1
            else:
                if column == 0:
                    new_row = row - 1
                    new_col = 8
                else:
                    new_row = row
                    new_col = column - 1
        elif type == 'column':
            if forward:
                if row == 8:
                    new_row = 0
                    new_col = column + 1
                else:
                    new_row = row + 1
                    new_col = column
            else:
                if row == 0:
                    new_row = 8
                    new_col = column - 1
                else:
                    new_row = row - 1
                    new_col = column
        elif type == 'box':
            row, column = sudoku.convert_row_box(row, column, to='box')
            if forward:
                if column == 8:
                    new_row = row + 1
                    new_col = 0
                else:
                    new_row = row
                    new_col = column + 1
            else:
                if column == 0:
                    new_row = row - 1
                    new_col = 8
                else:
                    new_row = row
                    new_col = column - 1
            # if new_row >= 0 and new_col >= 0:
            #     new_row, new_col = sudoku.convert_row_box(new_row, new_col, to='row')

        # simple error checking
        if new_row < 0 or new_col < 0 or new_row > 8 or new_col > 8:
            return -1, -1
        else:
            if type == 'box':
                new_row, new_col = sudoku.convert_row_box(new_row, new_col, to='row')
            return new_row, new_col


    ##########
    @staticmethod
    def step_by_dict(row, column, pool_dict, forward=True, type='row'):
        ''' find the 'next' square in the grid that is in the dict
            skips squares not in the dict, as these are not blank

        Positional arguments:
            row -- integer row number 0-8
            column -- integer column number 0-8
            pool_dict -- dictionary of available values
                uses (row, column) as keys, list of integers as values

        Keyword arguments:
            forward -- True/False to step forward, otherwise backwards
                (deafult True)
            type -- string type of sequence ('row', 'column', 'box')
                (default 'row')
                'row' -- across each row, starting at the top
                'column' -- down each column, starting on the left
                'box' -- through each box, starting at the top left

        Returns: (row, column) tuple
                returns (-1, -1) if it steps too far in either direction
        '''

        # check type input
        if type.lower().strip() not in ('row', 'column', 'box'):
            print 'invalid type %s, use (\'row\', \'column\', \'box\')' %(type)
            return

        while row >=0 and column >= 0:
            row, column = sudoku.step(row, column, forward=forward, type=type)
            if row == -1 or column == -1:
                break
            elif (row, column) in pool_dict:
                break

        return row, column


    ##########
    def generate_random_grid(self, blank=False):
        ''' populate a random, valid grid using depth-first-search
            must be run on an empty grid

        Keyword arguments:
            blank -- True/False to blank grid before generating
                it will not generate if it's not blank

        Returns: None
        '''
        
        if blank:
            sudoku.blank(self)
        else:
            # check that the grid is empty
            num_empty = sudoku.num_empty_squares(self)
            if num_empty < 81:
                print '%s square(s) are already filled in' %(81 - num_empty)
                print 'blank grid before generating a random grid'
                return

        iterations = 0
        dead_ends = 0
        success = True

        r, c = 0, 0

        # build the first row randomly
        row = random.sample(range(1, 10), 9)
        for e in row:
            sudoku.fill_square(self, r, c, e)
            c += 1
        r +=1
        c = 0

        pool_dict = sudoku.build_pool_dict(self)

        more_squares = True
        while more_squares:
            iterations += 1

            to_try = pool_dict.get((r, c), [])
            if to_try:
                # there are numbers to try in this square
                valid = sudoku.available_values_square(self, r, c)
                valid = list(set(valid) & set(pool_dict[(r, c)]))
                
                if valid:
                    # there are valid numbers to try for this square
                    val = random.sample(valid, 1)[0]
                    sudoku.fill_square(self, r, c, val)
                    r, c = sudoku.step(r, c, forward=True)
                    if r < 0: # no more squares
                        more_squares = False
                else:
                    # reached a dead-end
                    dead_ends += 1
                    pool_dict[(r, c)] = range(1, 10)
                    r, c = sudoku.step(r, c, forward=False)
                    val = self.data.loc[r, c]
                    sudoku.fill_square(self, r, c, 0)
                    pool_dict[(r, c)].remove(val)

        return iterations, dead_ends


    ##########
    def find_empty_squares(self, forward=True, type='row'):
        '''check whether a number exists in every square.

        Keyword arguments:
            forward -- True/False to step forward, otherwise backwards
                (deafult True)
            type -- string type of sequence ('row', 'column', 'box')
                (default 'row')
                'row' -- across each row, starting at the top
                'column' -- down each column, starting on the left
                'box' -- through each box, starting at the top left

        Returns: a list of row, column tuples of those squares
        '''

        empty_squares = []
        r, c = 0, 0
        if not forward:
            r, c = 8, 8

        while r >=0 and c >=0:
            if not self.data.iloc[r, c]:
                empty_squares.append( (r, c) )
            r, c = sudoku.step(r, c, forward=forward, type=type)

        return empty_squares


    ##########
    def solve_one_way(self, type='row', repeated=False, pool_dict=None):
        ''' solve a grid by filling in squares with one possible answer

        Keyword arguments:
            type -- string type of sequence ('row', 'column', 'box')
                (default 'row')
                'row' -- across each row, starting at the top
                'column' -- down each column, starting on the left
                'box' -- through each box, starting at the top left
            repeated -- True/False repeatedly solve with this method
                (default False)
            pool_dict -- dictionary of available values
                (defulat None ... if None, rebuilt by function)
                uses (row, column) as keys, list of integers as values

        Returns: True/False if changes made
        '''

        if not pool_dict:
            pool_dict = sudoku.build_pool_dict(self)

        found = False
        iteration = 0
    
        while (found and repeated) or iteration==0:
            found = False
            r, c = 0, 0
        
            while r >= 0 and c >= 0:
                vals = pool_dict.get((r, c), [])
                if len(vals) == 1:
                    found = True
                    sudoku.fill_square(self, r, c, vals[0])
                r, c = sudoku.step_by_dict(r, c, pool_dict, type=type)

            pool_dict = sudoku.build_pool_dict(self)
            iteration += 1

        if found or iteration > 0: # it was found at least once
            found = True

        return found


    ##########
    def find_empty_squares_single_item(self, row, column, type='row'):
        '''find the coordinates of empty squares within the row/column/box

        Positional arguments:
            row -- integer row number 0-8
            column -- integer column number 0-8

        Keyword arguments:
            type -- string type of sequence ('row', 'column', 'box')
                (default 'row')
                'row' -- within the current row
                'column' -- within the current column
                'box' -- within the current box

        Returns list of row, column tuples
        '''

        empty_squares = []
        r = row
        c = column

        if type == 'row':
            while r == row:
                if not self.data.iloc[r, c]:
                    empty_squares.append( (r, c) )
                r, c = sudoku.step(r, c, forward=True, type=type)
        elif type == 'column':
            while c == column:
                if not self.data.iloc[r, c]:
                    empty_squares.append( (r, c) )
                r, c = sudoku.step(r, c, forward=True, type=type)
        elif type == 'box':
            br, bc = sudoku.convert_row_box(r, c, to='box')
            box_row = br
            while br == box_row:
                if not self.data.iloc[r, c]:
                    empty_squares.append( (r, c) )
                r, c = sudoku.step(r, c, forward=True, type=type)
                if r >= 0 and c >= 0:
                    br, bc = sudoku.convert_row_box(r, c, to='box')
                else:
                    break

        return empty_squares


    ##########
    def solve_two_way(self, type='row', repeated=False, pool_dict=None):
        ''' solve a grid by filling in squares in a row/column/box that, 
            by excluding values that need to be in other squares,
            only one value is possible

        Keyword arguments:
            type -- string type of sequence ('row', 'column', 'box')
                (default 'row')
                'row' -- across each row, starting at the top
                'column' -- down each column, starting on the left
                'box' -- through each box, starting at the top left
            repeated -- True/False repeatedly solve with this method
                (default False)
            pool_dict -- dictionary of available values
                (defulat None ... if None, rebuilt by function)
                uses (row, column) as keys, list of integers as values

        Returns: True/False if changes made
        '''

        if not pool_dict:
            pool_dict = sudoku.build_pool_dict(self)

        found = False
        iteration = 0
    
        while (found and repeated) or iteration==0:
            found = False
            r, c = 0, 0
        
            while r >= 0 and c >= 0:
                empty_squares = sudoku.find_empty_squares_single_item(self, r, c, type=type)
                num_empty = len(empty_squares)
                if num_empty >= 2:
                    new_vals = {}
                    for i in empty_squares:
                        cur_set = set(pool_dict[i])
                        for j in empty_squares:
                            if i != j:
                                cur_set = cur_set - set(pool_dict[j])
                        if len(cur_set) == 1:
                            new_vals[i] = list(cur_set)[0]

                    if new_vals:
                        found = True
                        for r, c in new_vals.keys():
                            sudoku.fill_square(self, r, c, new_vals[(r, c)])

                if num_empty > 0:
                    r, c = empty_squares[-1]

                r, c = sudoku.step_by_dict(r, c, pool_dict, type=type)

            pool_dict = sudoku.build_pool_dict(self)
            iteration += 1

        if found or iteration > 0: # it was found at least once
            found = True

        return found


    ##########
    def num_empty_squares(self):
        '''count how many squares are empty

        Returns: integer
        '''

        num_empty_squares = 0
        for r in range(0, 9):
            for c in range(0, 9):
                if not self.data.iloc[r, c]:
                    num_empty_squares += 1
        return num_empty_squares


    ##########
    def show(self):
        '''create string version of grid
        '''
        
        print self


    ##########
    def copy(self):
        '''copy to a new instance
        '''
        
        # new = sudoku.__init__(self)
        # vals = []
        # for r in range(0,9):
        #     vals.extend(list(self.data.loc[r]))
        # new = sudoku.fill_list(new, vals)
        new = copy.deepcopy(self)
        return new

    ##########
    def solve_test(self, random_order=True, display=False, trial_num=None, 
        puzzle_name=None, puzzle_level=None):
        ''' solve the grid using a combination of 1- and
            2-step logic
            
            Positional arguments:
            g - sudoku grid
            
            Keyword arguments:
            random_order -- binary flag to use random selection of steps
            display -- binary flag to print info during run
            trial_num -- interger trial number for later aggregation
            puzzle_name -- string name for later aggregation
            puzzle_level -- string level for later aggregation
            
            returns pandas dataframe with rows for each step taken
        '''
        
        solved=False
        stepnum = 1
        steps = []
        stats = {'random_order': random_order}
        if puzzle_name:
            stats['name'] = puzzle_name
        if puzzle_level:
            stats['level'] = puzzle_level
        if trial_num:
            stats['trial_num'] = trial_num

        empty = sudoku.num_empty_squares(self)
        stats['start_num'] = empty
        f = sudoku.solve_one_way(self, repeated=True)
        num = sudoku.num_empty_squares(self)
        solved = sudoku.solved(self)
        s = stats.copy()
        s2 = {'step_num': stepnum, 'type': '1-way', 'repeated': True,
            'num_solved': empty - num}
        s.update(s2)
        empty = num
        steps.append(s)
        stepnum += 1

        static_way = 1
        while not solved:
            if random_order:
                way = random.sample(range(1, 4), 1)[0]
            else:
                way = static_way

            if way == 1:
                f = sudoku.solve_two_way(self, type='row', repeated=False)
                num = sudoku.num_empty_squares(self)
                s = stats.copy()
                s2 = {'step_num': stepnum, 'type': '2-way row', 
                     'repeated': False, 'num_solved':  empty - num}
                s.update(s2)
            elif way == 2:
                f = sudoku.solve_two_way(self, type='column', repeated=False)
                num = sudoku.num_empty_squares(self)
                s = stats.copy()
                s2 = {'step_num': stepnum, 'type': '2-way col', 
                     'repeated': False, 'num_solved':  empty - num}
                s.update(s2)
            elif way == 3:
                f = sudoku.solve_two_way(self, type='box', repeated=False)
                num = sudoku.num_empty_squares(self)
                s = stats.copy()
                s2 = {'step_num': stepnum, 'type': '2-way box', 
                     'repeated': False, 'num_solved':  empty - num}
                s.update(s2)

            two_way_num = s['num_solved']
            if two_way_num:
                steps.append(s)
            empty = num
            stepnum += 1

            f = sudoku.solve_one_way(self, repeated=False)
            num = sudoku.num_empty_squares(self)
            solved = sudoku.solved(self)
            s = stats.copy()
            s2 = {'step_num': stepnum, 'type': '1-way', 'repeated': True,
                'num_solved':  empty - num}
            s.update(s2)
            if num - empty:
                steps.append(s)
                stepnum += 1
            else:
                if not two_way_num:
                    static_way += 1
                if static_way > 3:
                    static_way = 1
            empty = num

            solved = g.solved()

        if display:
            print 'trial num', trial_num, ': num steps', stepnum - 1
        df = pd.DataFrame(steps)
        
        return df


    ##########
    def create_puzzle(self, num_blanks=45, steps_max = 20):
        '''build a human-solvable puzzle from an empty sudoku object

        Keyword arguments:
        num_blanks -- integer number of squares to blank out
            default 45
        steps_max -- integer number of maximum steps to be solvable
            default 20

        Returns: start grid, solution grid
        '''

        sudoku.generate_random_grid(self)
        grid_coords = [(r,c) for r in range(0,9) for c in range(0,9)]
        solvable = False

        while not solvable:
            # randomly blank squares
            grid = sudoku.copy(self)
            blanks = random.sample(range(0,81), num_blanks)
            for b in sorted(blanks):
                r, c = grid_coords[b]
                sudoku.fill_square(grid, r, c, 0)

            # check that the grid is solvable by a human
            df = sudoku.solve_test(self, random_order=True)
            if len(df.index) <= steps_max:
                solvable = True

        return grid, self


    ##########
    def to_list(self):
        '''convert the sudoku object into a list, starting in the top left
        and going across, then down

        Returns: list
        '''

        nums = []
        for i, r in self.data.iterrows():
            nums.extend(list(r))
        return nums


    ##########
    def string_value(self):
        '''convert underlying dataframes to store strings for testing
        '''

        for c in range(0,9):
            self.data[c] = self.data[c].astype(str)
            self.boxes[c] = self.boxes[c].astype(str)


    ##########
    @staticmethod
    def to_json(file, **kwargs):
        '''convert data to a dictionary and write to json file

        Positional arguments:
        **kwargs -- list of name and value pairs
            should be key and value, usually a list
        
        Returns nothing
        '''

        d = {}
        for k in kwargs:
            d[k] = kwargs[k]
        with open(file, 'w') as outfile:  
            json.dump(d, outfile)


    ##########
    def test_data(self, format='num'):
        '''fill in a grid with test data

        Keyword arguments:
            format -- string type ('num', 'str')

        Returns: None
        '''
        
        if format == 'num':
            sudoku.fill_list(self, [6,0,0,0,4,3,0,0,7,
                0,0,7,6,0,1,8,2,5,
                0,0,0,2,5,7,0,0,0,
                9,6,0,0,3,0,7,0,1,
                0,0,5,0,6,0,9,0,0,
                7,0,4,0,1,0,0,5,6,
                0,0,0,3,8,5,0,0,0,
                5,4,6,1,0,9,2,0,0,
                1,0,0,4,2,0,0,0,9])
        elif format == 'str':
            sudoku.fill_list(self, ['a','b','c','d','e','f','g','h','i',
                'j','k','l','m','n','o','p','q','r',
                's','t','u','v','w','x','y','z','A',
                'B','C','D','E','F','G','H','I','J',
                'K','L','M','N','O','P','Q','R','S',
                'T','U','V','W','X','Y','Z','1','2',
                '3','4','5','6','7','8','9','0','!',
                '@','#','$','%','^','&','*','(',')',
                '=','+','/','?',',','.','<','>','~'])


##########




