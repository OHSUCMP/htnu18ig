#!/usr/bin/python3.5
"""from selenium import webdriver
browser = webdriver.chrome()
type(browser)
browser.get('http://inventwithpython.com')"""
import re
import glob
import os
import shutil
import time
from selenium import webdriver
from selenium.webdriver.common.keys import Keys

#Get password and keys
logica_user_name = input("What is your Logica Sandbox username? ")
if logica_user_name == "":
	logica_user_name = "preston7063@gmail.com"
	print("using default: " + logica_user_name)
logica_password = input("What is your Logica Sandbox password? ")
if logica_password == "":
	logica_password = "GudricLogi1!"
	print("using default: "+ logica_password)

#Firefox version
driver = webdriver.Firefox()
driver.get("http://www.python.org")

assert "logica" in driver.title
elem = driver.find_element_by_name("q")
elem.clear()
elem.send_keys("pycon")
elem.send_keys(Keys.RETURN)
time.sleep(5) # Let the user actually see something!
assert "No results found." not in driver.page_source
driver.close()




"""
#Chrome version
driver = webdriver.Chrome()  # Optional argument, if not specified will search path.
type(driver)
driver.get('https://sandbox.logicahealth.org');

time.sleep(5) # Let the user actually see something!

alert = wait.until(EC.alert_is_present())
alert.send_keys('logica_user_name' + Keys.TAB + 'logica_password')
alert.accept()
"""
"""
search_box = driver.find_element_by_name('q')
search_box.send_keys('ChromeDriver')
search_box.submit()
time.sleep(5) # Let the user actually see something!
driver.quit()

try:
    elem = browser.find_element_by_class_name('bookcover')
    print('Found <%s> element with that class name!' % (elem.tag_name))
except:
    print('Was not able to find an element with that name.')
"""
print("Thanks for uploading all the files and directories")