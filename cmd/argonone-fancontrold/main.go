package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"periph.io/x/conn/v3/driver/driverreg"
	"periph.io/x/conn/v3/i2c"
	"periph.io/x/conn/v3/i2c/i2creg"
	_ "periph.io/x/host/v3/bcm283x"
	_ "periph.io/x/host/v3/rpi"
)

var temperatureBands = []map[string]int{
	{"temp": 50, "speed": 10},
	{"temp": 60, "speed": 50},
	{"temp": 65, "speed": 100},
}

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func initI2C() (*i2c.Dev, error) {
	_, err := driverreg.Init()
	if err != nil {
		return nil, err
	}

	b, err := i2creg.Open("")
	if err != nil {
		return nil, fmt.Errorf("Failed to initialise I2C: %w", err)
	}

	d := &i2c.Dev{Addr: 26, Bus: b}
	return d, nil
}

func getTemperature() (int, error) {
	t, err := os.ReadFile("/sys/class/thermal/thermal_zone0/temp")

	if err != nil {
		return 0, err
	}

	st := strings.TrimSpace(string(t))

	i, err := strconv.Atoi(st)

	if err != nil {
		return 0, err
	}

	return i / 1000, nil
}

func selectFanSpeed(temperature int) int {
	targetSpeed := 0

	for _, v := range temperatureBands {
		if temperature > v["temp"] {
			targetSpeed = v["speed"]
		}
	}

	return targetSpeed
}

func setFanSpeed(device *i2c.Dev, speed int) error {
	_, err := device.Write([]byte{byte(speed)})
	return err
}

func monitor(device *i2c.Dev) {
	temp, err := getTemperature()
	check(err)

	fanSpeed := selectFanSpeed(temp)
	fmt.Printf("Current temperature: %d; Target fan speed: %d\n", temp, fanSpeed)

	setFanSpeed(device, fanSpeed)
	check(err)
}

func main() {
	device, err := initI2C()
	check(err)

	ticker := time.NewTicker(30 * time.Second)

	for range ticker.C {
		monitor(device)
	}
}
