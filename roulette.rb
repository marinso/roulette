require 'watir'
require 'pry'

$LOGIN = ENV['LOGIN']
$PASSWORD = ENV['PASSWORD']
$URL = 'https://csgopolygon.com'

class Site < Watir::Browser
  def self.init
    Site.new(
      :chrome,
      options: {
        options: { 'excludeSwitches' => ['enable-automation'] },
        args: ['disable-infobars']
      }
    ).tap do |s|
      s.window.resize_to 1366, 786
      s.window.move_to 0, 0
    end
  end

  def login
    goto $URL
    text_field(id: 'login_username').set $LOGIN
    text_field(id: 'login_password').set $PASSWORD
    div(class: 'window_sign_in_buttons').buttons.first.click
    binding.pry
  end

  def game
    basic_bet = 10
    bet = 10
    last_bet = nil

    loop do
      next unless can_bet?

      puts "check_last_ball: #{check_last_ball}"
      puts "last_bet: #{last_bet}"
      sleep 2
      if check_last_ball != last_bet
        bet *= 2
        puts "W poprzedniej grze przegrałem - podwajam stawkę #{bet}"
        bet >= 320 ? wait_for_bet : nil
      else
        bet = basic_bet
        puts "W poprzedniej grze wygrałem - wracam do #{bet}"
      end

      bet_value(bet)

      case check_last_ball
      when 'red'
        puts "Stawiam na czerwone - stawiam #{bet} - stan konta #{check_balance.to_i - bet}"
        bet_on_red
        last_bet = 'red'
      when 'dark'
        puts "Stawiam na czarne - stawiam #{bet} - stan konta #{check_balance.to_i - bet}"
        bet_on_black
        last_bet = 'dark'
      when 'green'
        puts 'Wypadło zielone...'
        puts "Stawiam na czarne - stawiam #{bet} - stan konta #{check_balance.to_i - bet}"
        bet_on_black
        last_bet = 'dark'
      end
      puts '-' * 20
      wait_until_finished
    end
  end

  def wait_for_bet
    puts '-' * 30
    sleep 120
    puts '-' * 30
  end

  def bet_value(value)
    text_field(id: 'roulette_amount').set value
  end

  def check_balance
    div(class: 'bet_balance').text.split(' ')[1]
  end

  def check_last_ball
    ul(class: 'balls').lis.last.span.attribute_value('class')
  end

  def bet_on_red
    button(text: '1 to 7').click
  end

  def bet_on_black
    button(text: '8 to 14').click
  end

  def can_bet?
    span(class: 'progress_timer').text =~ /Rolling in/
  end

  def wait_until_finished
    begin
      div(class: 'bar').wait_until { |bar| bar.text == '' }
    rescue StandardError
      refresh
    end
    sleep 12
  end
end

site = Site.init
site.login
