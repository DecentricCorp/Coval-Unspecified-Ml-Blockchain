import gym
import universe # register the universe environments
import numpy as np
import cPickle as pickle

def forward(ob):
  """ 
  Takes raw (768,1024,3) uint8 screen and returns list of VNC events.
  The browser window indents the origin of MiniWob by 75 pixels from top and
  10 pixels from the left. The first 50 pixels along height are the query.
  """
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

env = gym.make('wob.mini.ClickButton-v0')
# automatically creates a local docker container
env.configure(remotes=1, fps=5,
              vnc_driver='go', 
              vnc_kwargs={'encoding': 'tight', 'compress_level': 0, 
                          'fine_quality_level': 100, 'subsample_level': 0})
observation_n = env.reset()
roundNumber = 0
while True:
  action_n = [forward(ob) for ob in observation_n] # your agent here
  observation_n, reward_n, done_n, info = env.step(action_n)
  env.render()
  print '-----------------complete' 
  #print 'observation:' 
  #print ob
  #pickle.dump(observation_n[0], f, -1)
  print 'reward_n'
  print reward_n[0]
  print reward_n[0] > 0.0
  print type(action_n[0])
  print action_n[0]
  if (len(action_n[0]) > 0):
        print 'Did stuff!'
        import itertools
        count = 0
        for _ in itertools.repeat(None, len(action_n[0])):
          x = action_n[0][count].x
          y = action_n[0][count].y
          buttonmask = action_n[0][count].buttonmask
          values = { 
            'x':x,
            'y':y,
            'buttonmask':buttonmask,
            'count':count,
            'round':roundNumber,
            'reward':int(float(reward_n[0]) * int(100000000))
             }
          # count
          # round
          # http get
          import urllib2
          from string import Template
          eventTemplate = Template("http://127.0.0.1:4333/v1/MachineLearning/ClickButton/saveEvent/exec?args=$round,$x,$y,$buttonmask")
          rewardTemplate = Template("http://127.0.0.1:4333/v1/MachineLearning/ClickButton/saveReward/exec?args=$round,$reward")
          print eventTemplate.substitute(values)
          urllib2.urlopen(eventTemplate.substitute(values)).read()
          count = count + 1
  if (reward_n[0] > 0.0):
        urllib2.urlopen(rewardTemplate.substitute(values)).read()
        print ('Earned reward', int(float(reward_n[0]) * int(100000000)))
      #do_something()
  #for i, event in len(action_n[0]):
  #  print i
  #print 'done_n'
  #print done_n 
  #print 'info'
  #print info
  #print '-----------------complete'
  roundNumber = roundNumber + 1
  print '-----------------complete'