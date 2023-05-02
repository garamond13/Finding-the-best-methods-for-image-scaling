# Finding the best methods for image scaling

There is no such thing as a universally best method or the best kernel function, or... Which methods and settings will be best for you will depend on your use case scenario. In this research, several scenarios will be tested using mpv player (https://mpv.io). Settings will be adjusted for the beset or close to best results on tested images (videos). I will try to restrain myself from making claims that this or that is the best or worst, I will try to base all claims on the test results, but do note that in different scenarios, you may get different results.

### Testing methodology
All test images were created directly from the same illustration (https://www.freepik.com/free-vector/vector-illustration-mountain-landscape_1215613.htm#query=illustrations&position=11&from_view=keyword&track=sph) in Adobe Illustrator with added text as extra details, and then they were converted with ffmpeg to mp4 with this command `ffmpeg -loop 1 -i input.png -c:v libx264 -t 60 -r 30 -pix_fmt yuv444p output.mp4`. Videos were then upscaled from lower resolutions to 1080p and compared to screenshot taken of the original 1080p video, in case of upscaling. The oposite was done in case of downscaling. For comparation was used dssim (https://en.wikipedia.org/wiki/Structural_similarity) in ImageMagick (https://imagemagick.org) with this command `magick compare -metric dssim org.png scaled.png x:`. For taking screenshots Single Menu Screenshot (https://github.com/garamond13/SingleMenuScreenshot) was used. The shaders and the config used in testing were modified as needed.

Notes that there is no perfect methodology for testing. I went with this methodology because of past experiences. This methodology also avoids blurring, ringing, and aliasing artifacts that occur in the preparation of test images by conventional scaling of the original image. Also, note that this image may not be very suitable for testing downscaling as it won’t have serious issues with aliasing. And it's possible that errors ocour during testing.

## Upscale (upsample)
### Ringing and anti-ringing
Reference on ringing https://en.wikipedia.org/wiki/Ringing_artifacts \
Let’s first establish whether we should use anti-ringing in further testing. Here we will test what amount of antiringing produces best results. The amount is in range [0.0, 1.0]. We will use altUpscaleHDR.glsl user shader with kernel-function=lanczos radius=2.0 blur=1.0. All tested resoultions are upscaled to 1080p.

anti-ringing amounts and corresponding dssim result
| resolution | 0.0 | 0.75 | 0.99 | 1.0 |
| --- | --- | --- | --- | --- |
| 720 | 0.0238535 | 0.0235485 | 0.0235562 | 0.0234667 |
| 540 | 0.0372175 | 0.0365213 | 0.0364534 | 0.0363607 |
| 360 | 0.0646968 | 0.0637967 | 0.0636646 | 0.0636103 |

Based on these results, it should be safe to assume that the optimal setting for anti-ringing is 1.0. However, we will perform a few more tests. We will use altUpscaleHDR.glsl user shader with kernel-function=welch radius=2.0 blur=1.0.

anti-ringing amounts and corresponding dssim result
| resolution | 0.99 | 1.0 |
| --- | --- | --- |
| 720 | 0.0229898 | 0.0228918 |
| 540 | 0.0360343 | 0.0359319 |
| 360 | 0.0632565 | 0.0631909 |

Now we will use altUpscaleHDR.glsl user shader with kernel-function=bicubic a=-0.5.

anti-ringing amounts and corresponding dssim result
| resolution | 0.75 | 1.0 |
| --- | --- | --- |
| 720 | 0.0236675 | 0.0235908 |
| 540 | 0.0366226 | 0.0364864 |
| 360 | 0.0638264 | 0.0636606 |

Again we are getting consistent results where 1.0 looks to be most optimal. Based on these results, we will use an anti-ringing value of 1.0 for further testing.

### Kernel functions
Reference on kernel https://en.wikipedia.org/wiki/Kernel_(image_processing) \
Kernel functions are used for the calculation of kernel weights. We will test a few types of scaling filters and several kernel functions. The filters we are going to test are mpv's ewa or polar (mpv --vo=gpu-next), at the time of the research my experimental jinc (which is similar to mpv's ewa or polar), and orthogonal or separated (alt-scale shaders). Kernel functions we are going to use here will be windowed sinc or jinc, or their alternatives.

Let’s first have a look at windowed sinc and the following windows: cosine, welch, lanczos (sinc window), hann, and hamming. For all of these windows, it can be said that they are controlled by the kernel radius. We will test at what radius these windows are giving best results. We will use altUpscaleHDR.glsl user shader with blur=1.0 anti-ringing=1.0.

720p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 4.6 | 0.0221655 |
| cosine | 4.5 | 0.0221147 |
| welch | 4.5 | 0.0220882 |
| hann | 6.6 | 0.0221957 |
| hamming | 5.9 | 0.0221789 |

540p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 4.3 | 0.0354828 |
| cosine | 4.3 | 0.035486 |
| welch | 4.3 | 0.0354907 |
| hann | 4.9 | 0.0354921 |
| hamming | 4.6 | 0.035502 |

360p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 2.7 | 0.0628738 |
| cosine | 2.6 | 0.0627836 |
| welch | 2.5 | 0.0627289 |
| hann | 3.4 | 0.0629509 |
| hamming | 3.7 | 0.0628955 |

Here, we can notice that all windows can achieve similar results. However, one other thing to note is that hann and hamming usually need a larger radius to achieve those results, which makes them worse in terms of performance.

Now lets test mpv's ewa or polar with these settings added to base config scale=ewa_lanczos scaler-lut-size=10 scale-window= scale-radius= scale-cutoff=0.0 scale-blur=1.0. For antiringing we will use https://github.com/haasn/gentoo-conf/blob/xor/home/nand/.mpv/shaders/antiring.hook without chroma part (default settings).

Note: dont confuse ewa_lanczos and lanczos, ewa_lanczos is jinc windowed jinc and lanczos is sinc windowed sinc, but sinc window is also called lanczos window. Here we will only test sinc windowed jinc (under the name lanczos) also known as ewa_ginseng.

720p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 3.0 | 0.0228769 |
| cosine | 2.9 | 0.0226756 |
| welch | 2.8 | 0.0225573 |
| hann | 5.3 | 0.0227386 |
| hamming | 4.4 | 0.022792 |

540p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 2.9 | 0.036318 |
| cosine | 2.9 | 0.036318 |
| welch | 2.7 | 0.0359962 |
| hann | 3.4 | 0.0366169 |
| hamming | 4.0 | 0.0365035 |

360p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 2.9 | 0.0638985 |
| cosine | 2.7 | 0.0635906 |
| welch | 2.7 | 0.0634135 |
| hann | 3.3 | 0.0641833 |
| hamming | 4.1 | 0.0641346 |

The results are very consistent. For similar radiuses, lanczos, cosine, and welch achieve their best overall results at lower radiuses compared to hann and hamming. This is why I will only test lanczos welch and hann in my experimental jinc (usually if not mentioned assume antiringing=1.0 and blur=1.0). 

720p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 3.0 | 0.0227903 |
| welch | 2.8 | 0.0224323 |
| hann | 5.3 | 0.0227661 |

540p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 2.9 | 0.0365359 |
| welch | 2.7 | 0.036151 |
| hann | 3.4 | 0.0368122 |

360p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 2.9 | 0.0642838 |
| welch | 2.7 | 0.0638784 |
| hann | 3.3 | 0.0645392 |

Again we are getting consitent results. Based on the last tests, we could conclude that windows controlled by radius can achieve around similar results, but some windows need higher radiuses to achieve those results.

So far, we have tested windows that don’t offer any control with free parameters. We only get to control them with radius. Now we will test windows with one free parameter blackman, power of cosine, and  here I will present the new window with one free parameter.

w(x) = `1.0 - pow(abs(x) / R, n)`, where n is in the range (0.0, +inf] and R is the kernel radius \
at n=1.0, w(x)=linear window \
at n=2.0, w(x)=welch window \
as n aproaches +inf, w(x)=box window \
I will refer to it as the garamond window.

Taking into consideration the fact that at n=2.0, the garamond window is exactly the same as the welch window, we will use the previous results of welch and test them against the garamond window at the same radius, and possibly lower radius. We will use my experimental jinc.

720p
| window | radius | dssim |
| --- | --- | --- |
| welch | 2.8 | 0.0224323 |
| garamond n=4.0 | 2.8 | 0.0221757 |
| garamond n=3.7 | 2.7 | 0.0221628 |

Using the garamond window, we were able to achieve better result at the same radius, and we were able to lower the radius further while achieving even better results.

Lets now test power of cosine with free parameter n. \
Few interisting facts about it: \
at n=0.0, box window \
at n=1.0, cosine window \
at n=2.0, hann window

We will use my experimental jinc and compare the results to welch because it achieved the best result in the previous test.

540p
| window | radius | dssim |
| --- | --- | --- |
| welch | 2.7 | 0.036151 |
| pow cosine n=0.6 | 2.7 | 0.0360422 |
| pow cosine n=0.4 | 2.5 | 0.0357687 |

Again we were able to achive better resut at the same radius, and we were able to lower the radius further while achieving even better results.

Now lets take the best result from earlier test and test blackman against it. (at a=0.16, common blackman). We will use altUpscaleHDR.glsl.

720p
| window | radius | dssim |
| --- | --- | --- |
| welch | 4.5 | 0.0220882 |
| blackman a=-0.8 | 4.5 | 0.0219042 |
| blackman a=-0.7 | 3.6 | 0.0218609 |

Again, we are getting consistent results. Based on this, we could conclude that these windows, still controlled by radius, and now with one free parameter, can achieve better results and further reduce the needed radius for those results compared to windows controlled only by radius.

Now, we will test the generalized normal window (gnw) and said, windows with two free parameters. One thing to note about them is that they are not affected by radius directly, as previously tested windows. We will take the best results from earlier test and test both against. We will use altUpscaleHDR.glsl.

720p
| window | radius | dssim |
| --- | --- | --- |
| welch | 4.5 | 0.0220882 |
| blackman a=-0.7 | 3.6 | 0.0218609 |
| gnw s=4.9 n=3.5 | 3.9 | 0.0219217 |
| said chi=0.16 eta=1.0 | 4.0 | 0.0220121 |

Here we can see that gnw and said can achive similar results. Now we will use my experimental jinc.

540p
| window | radius | dssim |
| --- | --- | --- |
| welch | 2.7 | 0.036151 |
| pow cosine n=0.4 | 2.5 | 0.0357687 |
| gnw s=3.0 n=2.9 | 2.5 | 0.0358475 |
| said chi=0.17 eta=0.0 | 2.5 | 0.0358198 |

And we are getting consistent results. Based on this, we could conclude that we are able to get at least close to the best results compared to kernel functions with one free parameter (which are affected by radius, so we could count it as a second parameter as well).

### Kernel blur
With the kernel blur we can control the kernel funcion's central lobe width. So far, we have conducted tests with a blur value of 1.0, which means neutral or off. Now, we will test whether we can improve results by adjusting the kernel blur. We will use altUpscaleHDR.glsl.

720p
| window | radius | blur | dssim |
| --- | --- | --- | --- |
| blackman a=-0.7 | 3.6 | 1.0 | 0.0218609 |
| blackman a=-0.7 | 3.6 | 0.93 | 0.0215603 |

Now we will use my experimental jinc.

540p
| window | radius | blur | dssim |
| --- | --- | --- | --- |
| pow cosine n=0.4 | 2.5 | 1.0 | 0.0357687 |
| pow cosine n=0.4 | 2.5 | 0.89 | 0.0346785 |

By adjusting the kernel blur, we were able to improve some of the best previous results.

### Sigmoidal upscale
Reference https://legacy.imagemagick.org/Usage/color_mods/#sigmoidal \
So far, tests were done in gamma light because of simplicity. Now, we will test upscaling in sigmoidal light. We control sigmoidal curve with contrast (c) and midpoint (m) parameters. Now we will compare gamma upscale (previous results altUpscaleHDR.glsl) and same settings in sigmoidal light using altUpscale.glsl.

720p
| window | radius | blur | dssim |
| --- | --- | --- | --- |
| blackman a=-0.7 (gamma) | 3.6 | 0.93 | 0.0215603 |
| blackman a=-0.7 (c=6.0 m=0.6) | 3.6 | 0.93 | 0.0214525 |

And now, I will modify my experimental jinc to upscale in sigmoidal light. For simplicity, I will use the same settings for sigmoidal light control.

540p
| window | radius | blur | dssim |
| --- | --- | --- | --- |
| pow cosine n=0.4 (gamma) | 2.5 | 0.89 | 0.0346785 |
| pow cosine n=0.4 (c=6.0 m=0.6) | 2.5 | 0.89 | 0.034432 |

By performing upscale in sigmoidal light, we were able to improve the results. Based on this, we could conclude that performing upscale in sigmoidal light can achieve better results. However, for most of the further testing, I will continue to use gamma light because of simplicity.

### Post-upscale sharpening
Now, we will test post-upscale sharpening, essentially, can we further improve the results? We will use unsharp mask which is controled by sigma value (s), its kernel radius (r) and sharpening amount (a). We wil still use sigmoidal light altUpscale.glsl.

720p
| window | radius | blur | dssim |
| --- | --- | --- | --- |
| blackman a=-0.7 (c=6.0 m=0.6) no sharpening | 3.6 | 0.93 | 0.0214525 |
| blackman a=-0.7 (c=6.0 m=0.6) s=1.1 r=2.0 a=0.1 | 3.6 | 0.93 | 0.0213019 |

And we are able to further iprove results by sharpening image after the upscale.

### Alternative kernel functions
Alternative kernel functions are mostly designed as alternatives to sinc. However, in this case, we will only test a few adjustable alternatives, meaning we should be able to adjust them to perform well with jinc as well. We will test bicubic with one free parameter (a) and a fixed radius of 2.0, bc-spline with two parameters (b) and (c) and a fixed radius of 2.0. Additionally, I will present here the new modified fsr kernel based on https://github.com/GPUOpen-Effects/FidelityFX-FSR .The original fsr kernel has one parameter (b) and a fixed radius of 2.0. The new modified fsr kernel has two parameters (b) and (c). The c parameter will have a similar effect to the kernel blur in windowed sinc and windowed jinc kernel functions. It will also have a similar effect to the (b) parameter of bc-spline.

modified fsr kernel, fixed radius 2.0 \
b != 0.0 && b != 2.0 && c != 0.0 \
`(1.0 / (2.0 * b - b * b) * (b / (c * c) * x * x - 1.0) * (b / (c * c) * x * x - 1.0) - (1.0 / (2.0 * b - b * b) - 1.0)) * (0.25 * x * x - 1.0) * (0.25 * x * x - 1.0)` \
at c=1.0, the original fsr kernel

Now we will test bicubic using altUpscaleHDR.glsl.

| resolution | a | dssim |
| --- | --- | --- |
| 720 | -1.1 | 0.0225256 |
| 540 | -0.8 | 0.0359437 |
| 360 | -0.9 | 0.0631531 |

Now we will test bicubic using my experimental jinc.

| resolution | a | dssim |
| --- | --- | --- |
| 720 | -0.7 | 0.0224556 |
| 540 | -0.7 | 0.0347427 |
| 360 | -0.6 | 0.0622983 |

Now we will test bc-spline using altUpscaleHDR.glsl.

| resolution | b and c | dssim |
| --- | --- | --- |
| 720 | b=-0.5, c=1.1 | 0.0219281 |
| 540 | b=-0.5 c=0.9 | 0.0346389 |
| 360 | b=-0.7 c=0.9 | 0.0619001 |

Now we will test bc-spline using my experimental jinc.

| resolution | b and c | dssim |
| --- | --- | --- |
| 720 | b=0.3 c=0.7 | 0.0218987 |
| 540 | b=0.2 c=0.7 | 0.0343549 |
| 360 | b=0.2 c=0.6 | 0.0621524 |

Now we will test modified fsr using altUpscaleHDR.glsl.

| resolution | b and c | dssim |
| --- | --- | --- |
| 720 | b=0.2, c=0.95 | 0.0218886 |
| 540 | b=0.2 c=0.88 | 0.034506 |
| 360 | b=0.2 c=0.94 | 0.0625743 |

Now we will test modified fsr using my experimental jinc.

| resolution | b and c | dssim |
| --- | --- | --- |
| 720 | b=0.43 c=1.06 | 0.0220508 |
| 540 | b=0.44 c=1.03 | 0.0344618 |
| 360 | b=0.44 c=1.04 | 0.0623959 |

Here, we are able to get results that are close to the windowed sinc and windowed jinc kernel functions. Based on these results, we could conclude that it is easier to achieve good results with bc-spline and modified fsr kernel compared to bicubic. This probably shouldn’t be surprising as bicubic has only one parameter compared to the two parameters in the previously mentioned kernel functions. Additionally, note that all three kernel functions use kernels with a radius of 2.0.

## Downscale (downsample)
Downscaling will be kept a bit simpler because it’s more straightforward if done correctly. The correct way to do downscaling is to use linear light because otherwise, the image can be significantly darkened (reference http://www.ericbrasseur.org/gamma.html). The kernel has to be scaled appropriately, and antiringing is generally bad because it can increase aliasing. These rules can be broken and yield better results on some images, but generally, for video with a lot of different frames (images), these rules should probably be enforced.

We will skip testing of many windows since we have already established that more adjustable windows can be adjusted for better results. We will test the power of the cosine window because for n=1 it’s a cosine window, and for n=2, it’s a hann window. We will also test the garamond window because for n=1, it’s a linear window, and for n=2, it’s a Welch window. Now we will use altDownscale.glsl.

540p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 2.2 | 0.0184956 |
| pow cosine n=0.8| 2.0 | 0.0185596 |
| garamond n=0.1| 2.4 | 0.0173727 |
| said chi=0.4 eta=0.0 | 2.0 | 0.0183955 |

720p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 2.1 | 0.0137789 |
| pow cosine n=1.3 | 2.0 | 0.0140686 |
| garamond n=0.1| 2.4 | 0.0132567 |
| said chi=0.5 eta=0.0 | 2.1 | 0.0138891 |

Based on these results we could conclude that the garamond window can be adjusted for the best results. Now we will use my experimental jinc.

540p
| window | radius | dssim |
| --- | --- | --- |
| lanczos | 2.5 | 0.0204201 |
| pow cosine n=0.6| 2.1 | 0.0206342 |
| garamond n=0.1| 2.7 | 0.0192115 |
| said chi=0.4 eta=0.0 | 2.2 | 0.0202307 |

And we are getting consistent results. Now we will test can we improve the results by adjusting the kernel blur. First we will use altDownscale.glsl.

540p
| window | radius | blur | dssim |
| --- | --- | --- | --- |
| garamond n=0.1 | 2.4 | 1.0 | 0.0173727 |
| garamond n=0.1 | 2.4 | 0.75 | 0.0153649 |

Now we will use my experimental jinc.

540p
| window | radius | blur | dssim |
| --- | --- | --- | --- |
| garamond n=0.1 | 2.7 | 1.0 | 0.0192115 |
| garamond n=0.1 | 2.7 | 0.69 | 0.0155021 |

Based on these results, we could conclude that the results can be improved by adjusting the kernel blur.

Now we will test alternative kernel functions. We will test only bc-spline and the modified fsr kernel. We will use altDownscale.glsl.

540p
| window | parameters | dssim |
| --- | --- | --- |
| bcspline | b=-0.5 c=0.6 | 0.0169073 |
| modified fsr | b=0.45 c=0.94 | 0.0177153 |

And now we will use my experimental jinc.

540p
| window | parameters | dssim |
| --- | --- | --- |
| bcspline | b=-0.1 c=0.2 | 0.016042 |
| modified fsr | b=0.53 c=0.94 | 0.0164078 |

These results may not be too impressive, but note that these kernel functions should be significantly faster and, on top of that, use a radius of 2.0.

Finally, I’m going to just mention that downscaling could be further improved by using pre-filtering (gaussian blur), which will reduce aliasing, and we could use post-scale sharpening for obvious reasons.
