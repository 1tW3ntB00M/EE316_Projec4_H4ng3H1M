// TODO: sending over uart causes inability to recieve over uart
//	do we need to wait until rx is empty to use tx?
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
#define WORD_MAX 45333;

int gameState = 0;

char getLetter(serialib);

string getWord(string);

void display(int);

void sendLCD(string,serialib,int,int);

int update(char);

bool isIn(char, string);

char getChar(serialib);

//=============================================================================================

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
	// //TODO: adjust com and baud
	// serial.openDevice("\\\\.\\COM5", 9600, SERIAL_DATABITS_8, SERIAL_PARITY_NONE, SERIAL_STOPBITS_1);

	// if(serial.isDeviceOpen())
    //     printf("device is open\n");
    // else
    // {
    //     printf("device is not open\n");
	// 	serial.closeDevice();
    //     return 1;
    // }

	for(;;)
	{
		//reset game state 
		gameState = 0;
		sendLCD("", serial, wins, games);
		printf("New game? (Y/N)\n");

		//cin >> yn;
		//serial.readChar(&yn);
		yn = getChar(serial);

		if(yn == 'Y')
		{
			//reset win con
			gameState++;
			winCon = 0;

			//increment number of games played
			games++;

			//get a random word and save it as the answer
			answer = getWord("./dictionary.txt");

			//reset available letters, and guessed letters
			availableLetters = alphaBet;

			guessed = "";

			//initialise the displayed word
			hiddenWord = "";

			for(int i = 0; i < answer.length(); i++)
			{
				hiddenWord = hiddenWord + '_';
			}

			display(1);
			sendLCD(hiddenWord, serial, wins, games);

			for(;;)
			{
				//guess = getLetter(serial);
				printf("guess a letter\n");
				guess = getChar(serial);

				winCon = update(guess);

				display(gameState);
				sendLCD(hiddenWord, serial, wins, games);

				if(winCon)
				{
					wins++;
					gameState = 8;
					sendLCD(answer, serial, wins, games);
					printf("\nWell done! You have solved %d puzzles out of %d\n", wins, games);

					//wait for input before breaking
					//cin >> yn;
					//serial.readChar(&yn);
					yn = getChar(serial);
					//if(isIn(yn, alphaBet))
					//{	
						break;
					//}
				}

				if(gameState == 7)
				{
					gameState = 9;
					sendLCD(answer, serial, wins, games);
					printf("\nSorry! The correct word was ");
					cout << answer;
					printf(". you have solved %d puzzles out of %d\n", wins, games);

					//wait for input before breaking
					//cin >> yn;
					//serial.readChar(&yn);
					yn = getChar(serial);
					break;
				}
			}
		}
		else if (yn == 'N')
		{
			break;
		}
	}

	gameState = 10;
	sendLCD(answer, serial, wins, games);
	printf("\ngame over\n");

	//close serial connection
	serial.closeDevice();

	return 0;
}

//=============================================================================================

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
		//serial.readChar(&letter);
		letter = getChar(serial);

		if(isIn(letter, alphaBet))
		{
			if(isIn(letter,guessed))
			{
				printf("You already guessed that,\n choose another letter!\n");
			}
			else
			{
				break;
			}
		}
	}

	return letter;
}

//=============================================================================================

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
	
	for(;;)
	{
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

		if(word.length() <= 16)
		{
			break;
		}
	}


	file.close();
	
	return word;
}

//=============================================================================================

void display(int x)
{
	//clear terminal
	system("cls");

	//print gallows
	switch(x)
	{
		case 1:
			wprintf(L"┌──┐\n");
			wprintf(L"│\n");
			wprintf(L"│\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 2:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ");printf("0\n");
			wprintf(L"│\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 3:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ");printf("0\n");
			wprintf(L"│  │\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 4:
			wprintf(L"┌──┐\n");
			wprintf(L"│  "); printf("0\n");
			wprintf(L"│ /│\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 5:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ");printf("0\n");
			wprintf(L"│ /│\\\n");
			wprintf(L"│\n");
			wprintf(L"┴\n");
			break;
		case 6:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ");printf("0\n");
			wprintf(L"│ /│\\\n");
			wprintf(L"│ /\n");
			wprintf(L"┴\n");
			break;
		case 7:
			wprintf(L"┌──┐\n");
			wprintf(L"│  ");printf("0\n");
			wprintf(L"│ /│\\\n");
			wprintf(L"│ / \\\n");
			wprintf(L"┴\n");
			break;
		default:
			wprintf(L"gamestate error, cannot display");
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
	cout 
	<< guessed;
	printf("\n\n");
}

//=============================================================================================

//TODO: need the serialib to send
//maybe writeString() for the word
//then ~5 writeBytes() for the gamestate
//and w/l
void sendLCD(string x, serialib serial, int wins, int loss)
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

	//open serial connection
	serial.openDevice("\\\\.\\COM6", 9600, SERIAL_DATABITS_8, SERIAL_PARITY_NONE, SERIAL_STOPBITS_1);

	//initialise 16 character word
	string sendWord = "                ";


	for(int i = 0; i < x.length(); i++)
	{
		sendWord[i] = x[i];
	}

	//initialise two byte win
	unsigned char wub = (wins >> 8) & 0b11111111;
	unsigned char wlb = wins & 0b11111111;

	//initialise two byte loss
	unsigned char lub = (loss >> 8) & 0b11111111;
	unsigned char llb = loss & 0b1111111;

	//initialise one byte game state
	unsigned char gs = (unsigned char) gameState;

	unsigned char gameData[5] = {wub, wlb, lub, llb, gs};

	//send 16 character word
	for(int i = 0; i < 15; i++)
	{
		serial.writeChar(sendWord[i]);
	}

	// //send wins
	// serial.writeBytes(&wub, 1U);
	// serial.writeBytes(&wlb, 1U);

	// //send losses
	// serial.writeBytes(&lub, 1U);
	// serial.writeBytes(&llb, 1U);

	// //send game state
	// serial.writeBytes(&gs, 1U);

	//send non-word game data
	serial.writeBytes(gameData, 5U);

	//clear an close connection
	serial.flushReceiver();
	serial.closeDevice();
}

//=============================================================================================

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

//=============================================================================================

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

//=============================================================================================

char getChar(serialib serial)
{
	serial.openDevice("\\\\.\\COM6", 9600, SERIAL_DATABITS_8, SERIAL_PARITY_NONE, SERIAL_STOPBITS_1);
	char buffer;
	int errorNum = 0;

	for(;;)
	{
		//TODO: what to do with timeout
		errorNum = serial.readChar(&buffer, 1000);
		//printf("%d", errorNum);

		if (isIn(buffer,alphaBet))
		{
			printf("%c\n", buffer);
			break;
		}
	}

	serial.flushReceiver();
	serial.closeDevice();
	return buffer;
}