# Bluetooth Salter Food Scales Swift
## A case study into connecting to bluetooth peripherals that don't have documentation and deliberately don't conform to service specifications.

Recently I've been challenging myself to connect to various pieces of bluetooth hardware and I have just finished working on connecting to Salters Bluetooth Food Scales. It was fairly straight forward apart from the Zero function. As Salter haven't issued any documentation for their scales, in terms of bluetooth usage for developers, this was slightly more challenging than it should have been. 

### My Initial Approach:

After using the base classes of my Heart Rate Sensor project and discovering / connecting to the scales the first task I set out to accomplish was to display the weight. Conventially through the (org.bluetooth.service.weight_scale) service this should be an easy task, which would normally result in multiplying the last two bytes by eachother - however this set of Salter scales doesn't abide by those specs. After looking through the properties of the available characteristics (FFE1, FFE2, FFE3, FFE4, FFE5) I decided that FFE1 looked like the most likely to contain the weight data. 

After printing each byte from that services data, it read as below (When there was nothing on the scale and the metric set to grams):

[8,7,3,1,0,0,0] 

The three zeroes looked promising. After placing something on the scales, the correct weight value appeared in the 6th byte. I changed the metric and the 7th byte changed to 1 - so we now know that the 6th byte contains weight and 7th byte contains the current metric (With a weight of 231g, the data looked like the below).

[8,7,3,1,0,231,0] 

7 ounces looked like this (1 meaning it's in ounces - the weight value needed dividing by 10 to achieve the oz value)

[8,7,3,1,0,70,1] 

I then removed the current item from the scales and placed something much heavier on the scales that weighed 582g. This then caused the scales to send the below data:

[8,7,3,1,2,70,0] 

I was aware that UInt8 values are limited to a max of 256 - so I immediately multiplied the newly changed 5th byte by 256 and added the weight value in byte 6, which worked perfectly across all metrics. So we now know that the 5th byte effectively works as a tally for weights that exceed 256 of their respective metric. 

So that's the weight dealt with...however figuring out how to zero the scales was an entirely different issue. 

## Working out the Zero Function

Initially I tried writing 0 to the 6th byte of the weight characteristic, taking the data from the other characteristics, changing each byte to 0 and writing it back - but none of these worked or made any change. 

I then tried looking for descriptors or anything that would give me any clue how to approach this - unfortunately Salter made all characteristics non-descript. 

Hitting a bit of a dead end I decided to see if I could monitor the data that is sent via bluetooth. While it looked like it would be almost impossible via an IPA / Sim it looked potentially possible via an APK running in a sim. After a few hours of tinkering, I managed to find that the data being written was as below:

[9,3,5]

This data didn't change no matter the metric, weight or how many times I pressed zero in the APK. So this must be the key! I didn't know which characteristic it was writing to, but with only 4 characteristics it wouldn't be hard to try each one until I got a result. After putting together a quick loop and writing [9,3,5] to each, it worked after writing to the FFE3 characteristic! Quite a long way to go about it, but unfortunately without any documentation you have to get a bit creative!

## Conclusion:

The challenge of figuring out how to work the zero functionality really made this project feel worthwhile. Now that this project is complete, any fitness or dieting app can now easily add functionality to connect to the only Bluetooth Food Scales on the market - which wasn't immediately possible before.

![](ezgif-6-3e4dc5693668.gif)
