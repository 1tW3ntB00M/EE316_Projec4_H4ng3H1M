// TODO: include string, and print, and terminal shtuff
#include <cstdio>
#include <iostream>
#include <string>
#include <random>
#include <fstream>
#include <cstdlib>
#include <locale.h>
#include <wchar.h>
#include "serialib.h"
using namespace std;
using std::string;

string answer;// = "TEST";

string hiddenWord;// = "____";

string alphaBet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

string availableLetters;

string guessed;

//this should be the number of lines in our text file
#define WORD_MAX 3;

int gameState = 0;

char getLetter(serialib);

string getWord(string);

void display(int);

void sendLCD(string);

int update(char);

bool isIn(char, string);

//TODO: printf problems
int main()
{
	char yn;
	char guess;
	int wins = 0;
	int games = 0;
	int winCon = 0;

	setlocale(LC_ALL,"en_US.UTF-8");
    //SetConsoleOutputCP(CP_UTF8);

	//open serial connection
	serialib serial = serialib();
	//TODO: adjust com and baud
	serial.openDevice("\\\\.\\COM3", 115200);

	if(serial.isDeviceOpen())
        printf("device is open\n");
    else
    {
        printf("device is not open\n");
		serial.closeDevice();
        return 1;
    }

	for(;;)
	{
		printf("New game?\n");

		//cin >> yn
		serial.readChar(&yn);

		if(yn == 'Y')
		{
			//reset game state
			gameState = 0;
			winCon = 0;

			//increment number of games played
			games++;

			//get a random word and save it as the answer
			answer = getWord("./diction.txt");

			//reset available letters, and guessed letters
			availableLetters = alphaBet;

			guessed = "";

			//initialise the displayed word
			hiddenWord = "";

			for(int i = 0; i < answer.length(); i++)
			{
				hiddenWord = hiddenWord + '_';
			}

			display(0);

			for(gameState = 0; gameState < 6; )
			{
				guess = getLetter(serial);

				winCon = update(guess);

				display(gameState);

				if(winCon)
				{
					wins++;
					printf("\nWell done! You have solved %d puzzles out of %d\n", wins, games);
					break;
				}

				if(gameState == 6)
				{
					printf("\nSorry! The correct word was %s. you have solved %d puzzles out of %d\n", answer, wins, games);
				}

				
			}

			printf("\ngame over\n");
		}
		else
		{
			break;
		}
	}

	//close serial connection
	serial.closeDevice();

	return 0;
}

char getLetter(serialib serial)
{
	//get letter from UART
	//check they havent already used the letter
	//if they havent return the letter
	//if they have prompt again
	
	char letter;

	printf("Guess a letter!\n");

	for(;;)
	{
		//cin >> letter;
		serial.readChar(&letter);

		if(isIn(letter,guessed))
		{
			printf("You already guessed that,\n choose another letter!\n");
		}
		else
		{
			break;
		}
	}

	return letter;
}

string getWord(string fileName)
{
	string word;

	//open text file
	ifstream file(fileName);

	if(!file.is_open())
	{
		printf("error opening file\n");
		return "";
	}
	else 
		printf("opened file\n");

	//generate a random number from (0, max line num -1)
	int lineNum = rand() % WORD_MAX;

	//adjust random number to (1,max line num)
	lineNum++;

	//probably a better way to do this
	//oh well
	//get line a random number of times
	//the last one will be our word
	for(int i = 0; i != lineNum; i++)
	{
		getline(file, word);
	}

	file.close();
	
	return word;
}

void display(int x)
{
	//print gallows
	switch(x)
	{
		case 0:
			wprintf(L"┌──┐\n");
			wprintf(L"│\n");
			wprintf(L"│\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 1:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ☺\n");
			wprintf(L"│\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 2:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ☺\n");
			wprintf(L"│  │\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 3:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ☺\n");
			wprintf(L"│ /│\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 4:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ☺\n");
			wprintf(L"│ /│\\\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 5:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ☺\n");
			wprintf(L"│ /│\\\n");
			wprintf(L"│ /\n");
			wprintf(L"┴\n");
			break;
		case 6:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ☺\n");
			wprintf(L"│ /│\\\n");
			wprintf(L"│ / \\\n");
			wprintf(L"┴\n");
			break;
	}	
	
	//print hidden word
	//printf("%s", hiddenWord);
	cout << hiddenWord;
	printf("\n");

	//print remaining alphabet
	//printf("%s", availableLetters);
	cout << availableLetters;
	printf("\n");

	//print guesses
	//printf("%s",guessed);
	cout << guessed;
	printf("\n\n");
}

//TODO: need the serialib to send
//maybe writeString() for the word
//then ~5 writeBytes() for the gamestate
//and w/l
void sendLCD(string x)
{
	//TODO: send the hiddenWord back through UART
	// send the game state back through uart
	// send number of wins agains number of total games
	// back through uart

	//I think the best way to do this would be
	//to always send 16 characters (regardless of
	//the actual word size), padding with whitespace
	//then after 16 characters always send game state,
	//wins, and games, as numbers in the same order
	//each time
}

int update(char x)
{
	//update the game based on the guessed letter
	//add the letter to the guessed string
	//remove the letter from the string of remaining letters
	//if the letter isnt in the secret word adance the game state
	//and add the letter(s) to the displayed word
	guessed = guessed + x;

	//remove the guessed letter from the list of avaialable letters
	for(int i = 0; i < 26; i++)
	{
		if(availableLetters[i] == x)
		{
			availableLetters[i] = ' ';
		}
	}
	
	//if the input letter is in the answer, update the hidden word to show 
	//all isntances of the guessed letter
	//else increment the game state (add another part to the man)
	if(isIn(x,answer))
	{
		//update the hiddenWord to display the letter
		for(int i = 0; i < answer.length(); i++)
		{
			if(answer[i] == x)
			{
				hiddenWord[i] = x;
			}
		}
	}
	else
	{
		gameState++;
	}

	//check to see if the hidden word has had all of its
	//letters revealed. if it hasnt return 0 to indicate
	//the game continues
//	for(int i = 0; i < length(answer); i++)
//	{
//		if(answer[i] != hiddenWord[i])
//			return 0;
//	}
//
//	//if we havent returned 0, then the hidden word is now
//	//the answer, return 1 to indicate the game has been won
//	return 1;

	if(answer == hiddenWord)
	{
		return 1;
	}

	return 0;
}

//helper function that returns true if the character x
//is in the string y
bool isIn(char x, string y)
{
	for(int i = 0; i < y.length(); i++)
	{
		if(y[i] == x)
			return true;
	}

	return false;
}
