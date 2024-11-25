package main

import (
	"fmt"
	"github.com/toujourser/openwechat/openwechat"
	"time"
)

func main() {
	bot := openwechat.Default(openwechat.Desktop)

	//// 注册消息处理函数
	//bot.MessageHandler = func(msg *openwechat.Message) {
	//	if msg.IsText() && msg.Content == "ping" {
	//		msg.ReplyText("pong")
	//	}
	//}
	// 注册登陆二维码回调
	bot.UUIDCallback = openwechat.PrintlnQrcodeUrl

	reloadStorage := openwechat.NewFileHotReloadStorage("token.json")
	// 登陆
	if err := bot.HotLogin(reloadStorage); err != nil {
		if err = bot.Login(); err != nil {
			println(err.Error())
			return
		}
	}

	groupmap, err := GetGroupName(bot)
	if err != nil {
		println(err.Error())
		return
	}
	bot.MessageHandler = func(msg *openwechat.Message) {
		if msg.IsRecalled() {
			fmt.Printf("[%s]-[Recalled]-[%s] %s: %s\n", time.Unix(msg.CreateTime, 0).Format("2006-01-02 15:04:05"), msg.MsgId, groupmap[msg.FromUserName], msg.Content)
		} else {
			fmt.Printf("[%s]-[%s] %s: %s\n", time.Unix(msg.CreateTime, 0).Format("2006-01-02 15:04:05"), msg.MsgId, groupmap[msg.FromUserName], msg.Content)
		}
	}

	//// 获取登陆的用户
	//self, err := bot.GetCurrentUser()
	//if err != nil {
	//	fmt.Println(err)
	//	return
	//}
	//
	//// 获取所有的好友
	//friends, err := self.Friends()
	//fmt.Println(friends, err)
	//
	//// 获取所有的群组
	//groups, err := self.Groups()
	//fmt.Println(groups, err)

	// 阻塞主goroutine, 直到发生异常或者用户主动退出
	if err := bot.Block(); err != nil {
		println(err.Error())
	}
}

func GetGroupName(bot *openwechat.Bot) (groupmap map[string]string, err error) {
	self, err := bot.GetCurrentUser()
	if err != nil {
		return nil, err
	}
	groups, err := self.Groups()
	if err != nil {
		return nil, err
	}
	groupmap = make(map[string]string)
	for _, group := range groups {
		groupmap[group.UserName] = group.NickName
	}
	return groupmap, nil
}

func GetUserName(bot *openwechat.Bot) (users map[string]string, err error) {
	self, err := bot.GetCurrentUser()
	if err != nil {
		return nil, err
	}
	friends, err := self.Friends()
	if err != nil {
		return nil, err
	}
	users = make(map[string]string)
	for _, friend := range friends {
		users[friend.UserName] = friend.NickName
	}
	return users, nil
}
