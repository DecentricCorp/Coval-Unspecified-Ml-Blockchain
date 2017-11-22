import gym
import universe # register the universe environments
import random
import numpy as np
import tflearn
from tflearn.layers.core import input_data, dropout, fully_connected
from tflearn.layers.estimator import regression
from statistics import median, mean
from collections import Counter

LR = 1e-3
env = gym.make("wob.mini.ClickButton-v0")
env.configure(remotes=1, fps=5,
              vnc_driver='go', 
              vnc_kwargs={'encoding': 'tight', 'compress_level': 0, 
                          'fine_quality_level': 100, 'subsample_level': 0})
observation_n = env.reset()
goal_steps = 500
score_requirement = 0.01
initial_games = 1
roundNumber = 0

"""
    Probably a better way to convert coordinates into a 2d array... but until then...
"""
def coordToArray(x, y):
    x = x - 10
    y = y - 125
    board = np.zeros((210, 160, 3))
    board[y][x] = 1
    return board

""" 
    Takes raw (768,1024,3) uint8 screen and returns list of VNC events.
    The browser window indents the origin of MiniWob by 75 pixels from top and
    10 pixels from the left. The first 50 pixels along height are the query.
"""
def forward(ob):
  if ob is None: return []

  x = ob['vision']
  crop = x[75:75+210, 10:10+160, :]               # miniwob coordinates crop
  xcoord = np.random.randint(0, 160) + 10         # todo: something more clever here
  ycoord = np.random.randint(0, 160) + 75 + 50    # todo: something more clever here

  # 1. move to x,y with left button released, and click there (2. and 3.)
  action = [universe.spaces.PointerEvent(xcoord, ycoord, 0),
            universe.spaces.PointerEvent(xcoord, ycoord, 1),
            universe.spaces.PointerEvent(xcoord, ycoord, 0)]

  return action

### https://www.youtube.com/watch?v=3zeg7H6cAJw: 
### Intro - Training a neural network to play a game with TensorFlow and Open AI
""" Random Agent: Now, let's just get a quick impression of what a random agent looks like """
def some_random_games_first(): 
    observation_n = env.reset()
    while True:
        action_n = [forward(ob) for ob in observation_n] # your agent here
        observation_n, reward_n, done_n, info = env.step(action_n)
        env.render()
        if (reward_n[0] > 0.0):
            print ('Earned reward', reward_n[0])
        
### Uncomment to see random agent in action                
# some_random_games_first()

### https://www.youtube.com/watch?v=RVt4EN-XdPA
### Training Data - Training a neural network to play a game with TensorFlow and Open AI p.2
""" Lets Learn: Now that you've seen what random is, can we learn from it? Absolutely """
def initial_population():
    observation_n = env.reset()
    # [OBS, MOVES]
    training_data = []
    # all scores:
    scores = []
    # just the scores that met our threshold:
    accepted_scores = []
    # iterate through however many games we want:
    episodes = []
    episode = []
    for gameNumber in range(initial_games):
        score = 0
        # moves specifically from this environment:
        game_memory = []
        # previous observation that we saw
        prev_observation = []
        # for each frame in 200
        for _ in range(goal_steps):
            # choose random action (0 or 1)
            # action = random.randrange(0,2)
            action_n = [forward(ob) for ob in observation_n]
            # do it!
            # observation, reward, done, info = env.step(action)
            observation_n, reward_n, done_n, info = env.step(action_n)
            #if type(observation_n[0]) != type(None) :
                #print('Observation', type(observation_n[0]), observation_n[0]["vision"])
            env.render()
            # notice that the observation is returned FROM the action
            # so we'll store the previous observation here, pairing
            # the prev observation to the action we'll take.
            # print('length of previous observation', len(prev_observation))
            if type(observation_n[0]) != type(None) :
                
                vision = observation_n[0]["vision"]
                print('vision shape', vision.shape)
                print('vision type', type(vision))
                print('1st dimension', vision[0][0].shape)
                print('2nd dimension', vision[1][1].shape)
                print('3rd dimension', vision[2].shape)

                
            if (reward_n[0] > 0):
                print('----------------- REWARD Detected - Game #:', gameNumber, ' ---------------')
                frame = vision[75:75+210, 10:10+160]
                frame = frame.copy().astype('uint8')
                episode.append([frame, reward_n[0], done_n, info, action_n])
                print('------ shape of frame', frame.shape)
                count = 0
                x = action_n[0][count].x
                y = action_n[0][count].y
                output = coordToArray(x, y)
                print('------ shapeof action', output.shape)
                #print('-------------------- time to cleanup I think', episode[0])
                prev_observation = vision
                game_memory.append([vision, action_n])                
                score+=reward_n[0]
                accepted_scores.append(score)
                #import itertools
                #for count in itertools.repeat(None, len(action_n[0])):
                buttonmask = action_n[0][count].buttonmask
                print('score', score)
                print('reward', reward_n)
                print('x', x, 'y', y)
                print('buttonmask', buttonmask)
                # convert coordinates unto 2d array
                
                # append to training data
                #print('SAVE vision too', game_memory[0][0])
                #print('output', output)
                #print('----------- Game memory', game_memory[0][0][0])
                
                #print('----------- action shape', output.shape)
            
                training_data.append([frame, output])
                #print('training_data', game_memory[0])
                #print('output', output)
                if done_n: 
                    episodes.append(episode)
                    episode = []
                    break

        # IF our score is higher than our threshold, we'd like to save
        # every move we made
        # NOTE the reinforcement methodology here. 
        # all we're doing is reinforcing the score, we're not trying 
        # to influence the machine in any way as to HOW that score is 
        # reached.
        """if score >= score_requirement:
            #print("game memory", game_memory)
            accepted_scores.append(score)
            for data in game_memory:
                # convert to one-hot (this is the output layer for our neural network)
                if data[1] == 1:
                    output = [0,1]
                elif data[1] == 0:
                    output = [1,0]
                    
                # saving our training data
                training_data.append([data[0], output])"""

        # reset env to play again
        # env.reset()
        # save overall scores
        print('collected %d episodes.' % (len(episodes)))
        print('frame type', type(episodes[0][0])) # print episodes #0, frame #0, reward
        scores.append(score)
    
    # just in case you wanted to reference later
    training_data_save = np.array(training_data)
    np.save('saved.npy',training_data_save)
    
    # some stats here, to further illustrate the neural network magic!
    print('Average accepted score:',mean(accepted_scores))
    print('Median score for accepted scores:',median(accepted_scores))
    print(Counter(accepted_scores))
    
    return training_data

### Uncomment to visualize training data 
# initial_population()


### https://www.youtube.com/watch?v=G-KvpNGudLw
### Training Model - Training a neural network to play a game with TensorFlow and Open AI p.3
""" Neural Network Code : Now we will make our neural network. We're just going to use a simple multilayer perceptron model """
def neural_network_model(input_size):
    print('input data', input_data)
    network = input_data(shape=[210, 160, 3], name='input')

    network = fully_connected(network, 128, activation='relu')
    network = dropout(network, 0.8)

    network = fully_connected(network, 256, activation='relu')
    network = dropout(network, 0.8)

    network = fully_connected(network, 512, activation='relu')
    network = dropout(network, 0.8)

    network = fully_connected(network, 256, activation='relu')
    network = dropout(network, 0.8)

    network = fully_connected(network, 128, activation='relu')
    network = dropout(network, 0.8)

    network = fully_connected(network, 2, activation='softmax')
    network = regression(network, optimizer='adam', learning_rate=LR, loss='categorical_crossentropy', name='targets')
    model = tflearn.DNN(network, tensorboard_dir='log')

    return model

def train_model(training_data, model=False):
    #print('shape 0', training_data[0].shape)
    #print('shape 1', training_data[1].shape)
    #print('0th type', type(training_data[0][0]))
    #print('0th len', len(training_data[0][0]))
    #print('1st', type(training_data[0][1]))

    X = np.array([i[0] for i in training_data]).reshape(-1,len(training_data[0][0]),1)
    #y = [i[1] for i in training_data]

    if not model:
        model = neural_network_model(input_size = len(X[0]))
    #print('action shape', len(training_data[0]), len(training_data[1]))
    #action = training_data[0][1][75:75+210, 10:10+160]
    #action = action.copy().astype('uint8')
    print('------------shapes')
    #print('y', y[0].shape)
    #print('x', X.shape)
    print('training 0 0', training_data[0][0].shape)
    print('training 0 1', training_data[0][1].shape)
    model.fit({'input': training_data[0][0]}, {'targets': training_data[0][1]}, n_epoch=5, snapshot_step=500, show_metric=True, run_id='openai_learning')
    return model

""" Let's produce the training data: """
training_data = initial_population()

""" Train: let's train our neural network on this data that gave us these scores """
model = train_model(training_data)
#print('ready with trained model', model)

### https://www.youtube.com/watch?v=HCBX2cuA5UU
### Testing Network - Training a neural network to play a game with TensorFlow and Open AI p.4
""" Test: 
    Now, we're going to use code very similar to the initial_population function,
    the only major difference is that, rather than using a random action, we'll generate an action FROM our neural network instead. 
    We're going to go ahead and visualize these as well, and then save some stats
"""

"""scores = []
choices = []
for each_game in range(10):
    score = 0
    game_memory = []
    prev_obs = []
    env.reset()
    for _ in range(goal_steps):
        env.render()

        if len(prev_obs)==0:
            action = random.randrange(0,2)
        else:
            action = np.argmax(model.predict(prev_obs.reshape(-1,len(prev_obs),1))[0])

        choices.append(action)
                
        new_observation, reward, done, info = env.step(action)
        prev_obs = new_observation
        game_memory.append([new_observation, action])
        score+=reward
        if done: break

    scores.append(score)

print('Average Score:',sum(scores)/len(scores))
print('choice 1:{}  choice 0:{}'.format(choices.count(1)/len(choices),choices.count(0)/len(choices)))
print(score_requirement)"""