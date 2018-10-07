package main

import (
	"net/http"
	"regexp"
	"strings"

	"github.com/mattermost/mattermost-server/model"
	"github.com/mattermost/mattermost-server/plugin"
)

type Plugin struct {
	plugin.MattermostPlugin
}

func main() {
	plugin.ClientMain(&Plugin{})
}

func (p *Plugin) OnActivate() error {
	return nil
}

func (p *Plugin) ServeHTTP(c *plugin.Context, w http.ResponseWriter, r *http.Request) {
	switch path := r.URL.Path; path {
	default:
		http.NotFound(w, r)
	}
}

func (p *Plugin) ReplaceMatch(match string) string {
	if match == "\\$" {
		return "$"
	}
	if strings.HasPrefix(match, "$$") {
		return "\n```latex\n" + match[2:len(match)-2] + "```\n"
	}
	return "`latex" + match[1:len(match)-1] + "`"
}

func (p *Plugin) FilterPost(post *model.Post) (*model.Post, string) {
	re := regexp.MustCompile(`(\\\$|\$\$([\s\S]*?[^\\](\\\\)*)\$\$|\$([\s\S]*?[^\\](\\\\)*)\$)`)
	post.Message = re.ReplaceAllStringFunc(post.Message, p.ReplaceMatch)
	return post, ""
}

func (p *Plugin) MessageWillBePosted(c *plugin.Context, post *model.Post) (*model.Post, string) {
	return p.FilterPost(post)
}

func (p *Plugin) MessageWillBeUpdated(c *plugin.Context, newPost *model.Post, _ *model.Post) (*model.Post, string) {
	return p.FilterPost(newPost)
}
