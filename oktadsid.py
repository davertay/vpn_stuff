
from __future__ import print_function
import sys
import keyring
import getpass

from datetime import datetime

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import TimeoutException

# Global Setup
verbose = False

timeoutFail = False

# If we are already have a session we need to click the continue button
continueButtonLocator = (By.ID, "btnContinue")
# Identify the confirmation screen by the presence of the sign out button
signoutButtonLocator = (By.ID, "imgNavSignOut")


class Log():
    Debug = "debug"
    Error = "error"

def msg(level, msg):
    if level == Log.Error:
        print(msg, file=sys.stderr)
    elif level == Log.Debug and verbose:
        print(str(datetime.now().time()) + ": " + msg)

def read_the_password(dname, uname):
    msg(Log.Debug, "Get password")
    try:
        pw = keyring.get_password(dname, uname)
    except:
        print("Hint: to avoid password prompt add it to the keychain with Keychain Item Name=" + dname + " and Account Name=" + uname)
        try:
            pw = getpass.getpass()
        except:
            return None
    return pw

# Use with WebDriverWait to combine expected_conditions
class AnyEc:
    def __init__(self, *args):
        self.ecs = args
    def __call__(self, driver):
        for fn in self.ecs:
            try:
                if fn(driver): return True
            except:
                pass

# Find an element using a locator tuple or None if not found
# Note if driver.implicitly_wait() is set this will block
# By NOT setting an implicit wait we can check/fail and return immediately
def find_element(driver, locator):
    msg(Log.Debug, "Find element " + locator[0] + " = '" + locator[1] + "'")
    findIt = {
        By.ID: lambda p: driver.find_element_by_id(p),
        By.CSS_SELECTOR: lambda p: driver.find_element_by_css_selector(p),
        By.XPATH: lambda p: driver.find_element_by_xpath(p)
    }
    try:
        element = findIt[locator[0]](locator[1])
    except NoSuchElementException:
        return None
    return element

# Explicitly wait for an element and return it if found
# If anything from "others" is found instead we stop waiting and return None
def wait_for_element(driver, locator, others):
    # Early exit if we already timed out once
    global timeoutFail
    if timeoutFail:
        return None
    msg(Log.Debug, "Waiting for element " + locator[0] + " = '" + locator[1] + "'")
    locators = [locator] + others
    exceptions = list(map(lambda x: EC.presence_of_element_located(x), locators))
    try:
        WebDriverWait(driver, 20).until(AnyEc(*exceptions))
    except TimeoutException:
        timeoutFail = True
        msg(Log.Error, "Timeout waiting for " + locator[0] + " = '" + locator[1] + "'")
        return None
    return find_element(driver, locator)

def username_or_die():
    username = getpass.getuser()
    if not username:
        msg(Log.Error, "Could not read username derp out")
        sys.exit(1)
    return username

def password_or_die(host, uname):
    password = read_the_password(host, uname)
    if not password:
        msg(Log.Error, "Could not read password derp out")
        sys.exit(1)
    return password

def open_vpn_auth_page(url):
    options = Options()
    options.headless = True
    driver = webdriver.Chrome(options=options)
    #driver.implicitly_wait(10)
    driver.set_window_rect(width=600, height=400)
    msg(Log.Debug, "Loading " + url)
    driver.get(url)
    return driver


def fill_and_submit_login_form(driver, uname, pword):
    un_element = wait_for_element(driver, (By.ID, "okta-signin-username"), [continueButtonLocator, signoutButtonLocator])
    if un_element:
        msg(Log.Debug, "Fill username and password")
        un_element.clear()
        un_element.send_keys(uname)
        pw_element = driver.find_element_by_id("okta-signin-password")
        pw_element.clear()
        pw_element.send_keys(pword)
        submit_button = driver.find_element_by_id("okta-signin-submit")
        msg(Log.Debug, "Click login button")
        submit_button.click()

def submit_otp_push_form(driver):
    otp_push_button = wait_for_element(driver, (By.XPATH, "//div[@id='okta-sign-in']//input[@value='Send Push']"), [continueButtonLocator, signoutButtonLocator])
    if otp_push_button:
        msg(Log.Debug, "Click otp button")
        otp_push_button.click()

def submit_continue_session(driver):
    # EC.title_is("Pulse Connect Secure - Confirmation"),
    continue_session_button = wait_for_element(driver, continueButtonLocator, [signoutButtonLocator])
    if continue_session_button:
        msg(Log.Debug, "Click continue button")
        continue_session_button.click()

def find_and_print_cookie(driver):
    sign_out_button = wait_for_element(driver, signoutButtonLocator, [])
    cookie = driver.get_cookie("DSID")
    if sign_out_button and cookie:
        print("DSID=" + cookie['value'])
        return 0
    else:
        msg(Log.Error, "Failed to obtain DSID cookie")
        return 1

def get_the_dsid(vpnHost, vpnUrl):
    uname = username_or_die()
    pword = password_or_die(vpnHost, uname)
    driver = open_vpn_auth_page(vpnUrl)
    fill_and_submit_login_form(driver, uname, pword)
    submit_otp_push_form(driver)
    submit_continue_session(driver)
    rc = find_and_print_cookie(driver)
    driver.close()
    driver.quit()
    return rc

if __name__ == "__main__":
    vpnHost = "vpn-sac.groupondev.com"
    vpnUrl = "https://" + vpnHost + "/saml"
    rc = get_the_dsid(vpnHost, vpnUrl)
    sys.exit(rc)

